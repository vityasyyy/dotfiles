// Warn before the hard context limit so the agent can roll over deliberately.
// The hook must never throw: it runs inside the model request path.
// Editing this file requires `opencode service restart`: the runtime watcher
// cannot import a symlinked plugin file and logs a failed-load warning.
const WARN_LEVELS = [0.8, 0.9]
const CHARS_PER_TOKEN = 4

function estimateTokens(event) {
  try {
    const chars =
      JSON.stringify(event.messages ?? []).length +
      JSON.stringify(event.system ?? []).length +
      JSON.stringify(event.tools ?? {}).length
    return Math.ceil(chars / CHARS_PER_TOKEN)
  } catch {
    return 0
  }
}

export default {
  id: "context-rollover",
  async setup(ctx) {
    const limits = new Map()
    const warned = new Map()
    const reported = new Set()
    console.error("[context-rollover] loaded")

    const contextLimit = async (model) => {
      const key = `${model.providerID}/${model.id}`
      if (limits.has(key)) {
        return limits.get(key)
      }
      // ctx.model is the client API: list() resolves to { location, data: ModelInfo[] }.
      const result = await ctx.model.list()
      const models = Array.isArray(result) ? result : (result?.data ?? [])
      const found = models.find(
        (candidate) =>
          candidate.providerID === model.providerID && candidate.id === model.id,
      )
      const limit = found?.limit?.context
      // Only cache hits, so a model that appears after a provider reload is picked up.
      if (limit) {
        limits.set(key, limit)
      }
      return limit
    }

    await ctx.session.hook("context", async (event) => {
      try {
        const model = event?.model
        if (!model?.providerID || !model?.id || !event?.sessionID) {
          return
        }
        const limit = await contextLimit(model)
        if (!limit || !Array.isArray(event.system)) {
          return
        }

        const ratio = estimateTokens(event) / limit
        const level =
          [...WARN_LEVELS].reverse().find((value) => ratio >= value) ?? 0
        if (!level) {
          warned.delete(event.sessionID)
          return
        }

        const previous = warned.get(event.sessionID) ?? 0
        if (level <= previous) {
          return
        }
        warned.set(event.sessionID, level)

        event.system.push({
          type: "text",
          text: `[context-rollover] Context use is about ${Math.round(ratio * 100)}% of the ${limit}-token model window. Load the "handoff" skill now, write the handoff, then run ~/.agents/skills/handoff/scripts/session-handoff start --handoff <path>. Tell the user the successor session id and title. Do not start new work in this session.`,
        })
      } catch (error) {
        // A broken warning must not fail the model request.
        if (!reported.has(event?.sessionID)) {
          reported.add(event?.sessionID)
          console.error("[context-rollover] warning skipped", error)
        }
      }
    })
  },
}
