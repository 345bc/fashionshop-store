import { startPostView, recordPostView, isPostAbort, PostRequestError } from "./postService";

/** Accumulate ten seconds only while the successfully loaded article tab is visible. */
export function trackPostView(slug: string, onCount: (views: number) => void,
  page: Pick<Document, "visibilityState" | "addEventListener" | "removeEventListener"> = document,
  now: () => number = () => performance.now()) {
  const controller = new AbortController();
  let timer: ReturnType<typeof setTimeout> | undefined;
  let elapsed = 0;
  let visibleSince: number | null = null;
  let token = "";
  let minimumMs = 10000;
  let sending = false;
  let done = false;
  let failures = 0;
  let renewed = false;
  function settle() {
    if (visibleSince != null) elapsed += Math.max(0, now() - visibleSince);
    visibleSince = null;
    clearTimeout(timer);
  }
  function schedule() {
    settle();
    if (done || sending || !token || controller.signal.aborted || page.visibilityState !== "visible") return;
    visibleSince = now();
    timer = setTimeout(submit, Math.max(0, minimumMs - elapsed));
  }
  async function submit() {
    settle();
    if (page.visibilityState !== "visible" || done || controller.signal.aborted) return;
    if (elapsed < minimumMs) { schedule(); return; }
    sending = true;
    try {
      const result = await recordPostView(slug, token, controller.signal);
      if (!controller.signal.aborted) {
        done = true;
        page.removeEventListener("visibilitychange", schedule);
        onCount(result.viewCount);
      }
    } catch (error) {
      if (isPostAbort(error) || controller.signal.aborted) return;
      if (error instanceof PostRequestError && error.status === 410 && !renewed) {
        renewed = true; token = ""; elapsed = 0; sending = false;
        await begin();
        return;
      }
      failures++;
      if (failures < 3) timer = setTimeout(schedule, 2000);
    } finally { sending = false; }
  }
  async function begin() {
    try {
      const session = await startPostView(slug, controller.signal);
      if (controller.signal.aborted) return;
      token = session.token;
      minimumMs = Math.max(10, session.minimumSeconds) * 1000;
      schedule();
    } catch (error) {
      if (isPostAbort(error) || controller.signal.aborted) return;
      failures++;
      if (failures < 3) timer = setTimeout(() => { void begin(); }, 2000);
    }
  }
  page.addEventListener("visibilitychange", schedule);
  void begin();
  return () => {
    done = true; controller.abort(); settle();
    page.removeEventListener("visibilitychange", schedule);
  };
}
