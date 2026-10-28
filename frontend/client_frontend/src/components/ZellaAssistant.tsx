"use client";

/* eslint-disable @next/next/no-img-element -- Chat supports local uploads and validated catalog/size-chart media. */

import { useEffect, useMemo, useRef, useState, type ChangeEvent, type FormEvent } from "react";
import dynamic from "next/dynamic";
import Link from "next/link";
import type { CatalogSuggestion } from "@/service/imageRecognitionService";
import { usePathname } from "next/navigation";
import { useAuth } from "@/auth/AuthContext";
import { recognizeImage, describeRecognition, garmentName, catalogSearchUrl } from "@/service/imageRecognitionService";
import { sendChatMessage, type ChatReply } from "@/service/chatService";
import GoogleSymbol from "@/components/ui/GoogleSymbol";
import styles from "./ZellaAssistant.module.css";

const BotAvatar = dynamic(() => import("bot-avatars").then(module => module.BotAvatar), { ssr: false });

type Message = ChatReply & { from: "bot" | "user"; suggestions?: CatalogSuggestion[]; retryImage?: string; retryText?: string; image?: { url: string; name: string }; streaming?: boolean };
const welcome: Message = { from: "bot", text: "Xin chào! Mình là Zella, trợ lý thời trang. Mình có thể giúp bạn chọn size, phối đồ hoặc tìm mẫu trang phục qua tin nhắn và hình ảnh." };
const topics = [
  { label: "Kiểu dáng", question: "Dáng quả lê nên mặc gì?" },
  { label: "Dịp mặc", question: "Đi làm nên mặc gì?" },
  { label: "Màu sắc", question: "Da ngăm hợp màu nào?" },
  { label: "Chọn size", question: "Tư vấn chọn size" },
  { label: "Theo ngân sách", question: "Tìm sản phẩm dưới 300k" },
];

function StreamingText({
  text,
  onScroll,
  onComplete,
}: {
  text: string;
  onScroll?: () => void;
  onComplete?: () => void;
}) {
  const parts = useMemo(() => text.split(/(\s+)/), [text]);
  const [index, setIndex] = useState(1);
  const onCompleteRef = useRef(onComplete);
  const onScrollRef = useRef(onScroll);

  useEffect(() => {
    onCompleteRef.current = onComplete;
    onScrollRef.current = onScroll;
  });

  useEffect(() => {
    if (index >= parts.length) {
      onCompleteRef.current?.();
      return;
    }
    const step = parts[index] && /^\s+$/.test(parts[index]) ? 2 : 1;
    const timer = setTimeout(() => {
      setIndex(i => Math.min(i + step, parts.length));
      onScrollRef.current?.();
    }, 50);
    return () => clearTimeout(timer);
  }, [index, parts]);

  return (
    <>
      {parts.slice(0, index).map((part, i) =>
        /^\s+$/.test(part) ? (
          part
        ) : (
          <span
            key={i}
            className={`${styles.streamingWord} ${i >= index - 2 ? styles.streamingWordActive : ""}`}
          >
            {part}
          </span>
        )
      )}
      {index < parts.length && <span className={styles.streamingBeam} aria-hidden="true" />}
    </>
  );
}
export default function ZellaAssistant() {
  const pathname = usePathname();
  const { status, user } = useAuth();
  const [open, setOpen] = useState(false);
  const [hintVisible, setHintVisible] = useState(false);
  const hidden = /^\/(login|register|checkout|order-success|connection-error|support-chat)(\/|$)/.test(pathname);
  const widget = useRef<HTMLDivElement>(null);
  const launcher = useRef<HTMLButtonElement>(null);
  const close = useRef<HTMLButtonElement>(null);
  useEffect(() => {
    const show = () => setOpen(true);
    window.addEventListener("zella:open-chat", show);
    if (new URLSearchParams(window.location.search).get("chat") === "1") show();
    return () => window.removeEventListener("zella:open-chat", show);
  }, [pathname]);
  useEffect(() => {
    if (!open) return;
    close.current?.focus();
    const escape = (event: KeyboardEvent) => {
      if (event.key === "Escape") { setOpen(false); requestAnimationFrame(() => launcher.current?.focus()); }
    };
    window.addEventListener("keydown", escape);
    return () => window.removeEventListener("keydown", escape);
  }, [open]);
  useEffect(() => {
    if (status !== "authenticated" || !user || hidden) return;
    const key = "zella_chat_login_hint";
    let expiresAt: number;
    try {
      const saved = sessionStorage.getItem(key);
      expiresAt = saved === null ? Date.now() + 5000 : Number(saved);
      if (saved === null) sessionStorage.setItem(key, String(expiresAt));
    } catch {
      // No persistent hint when session storage is unavailable.
      return;
    }
    const remaining = expiresAt - Date.now();
    if (!Number.isFinite(remaining)) return;
    const show = window.setTimeout(() => setHintVisible(remaining > 0), 0);
    const hide = window.setTimeout(() => setHintVisible(false), Math.max(0, remaining));
    return () => { window.clearTimeout(show); window.clearTimeout(hide); };
  }, [status, user, hidden]);
  useEffect(() => {
    if (!open) return;
    const outside = (event: PointerEvent) => {
      if (event.target instanceof Node && !widget.current?.contains(event.target)) setOpen(false);
    };
    document.addEventListener("pointerdown", outside);
    return () => document.removeEventListener("pointerdown", outside);
  }, [open]);
  if (hidden || status !== "authenticated" || !user) return null;
  return <div ref={widget} className={styles.widget}>
    <section hidden={!open} id="store-chat" className={styles.panel} role="dialog" aria-modal="false" aria-labelledby="store-chat-title">
      <header className={styles.header}><div><span className={styles.eyebrow}>ZELLA CARE</span><h2 id="store-chat-title">Tư vấn thời trang</h2></div><button ref={close} type="button" aria-label="Đóng chat" onClick={() => { setOpen(false); requestAnimationFrame(() => launcher.current?.focus()); }}><GoogleSymbol name="close" /></button></header>
      <Conversation key={String(user.id ?? "current")} onClose={() => setOpen(false)} />
    </section>
    {hintVisible && status === "authenticated" && !open && <div className={styles.loginHint} role="status"><span className={styles.hintIcon}><GoogleSymbol name="auto_awesome" size={18} /></span><div><strong>Khám phá cùng Zella</strong><p>Chatbot gợi ý sản phẩm cho bạn</p></div></div>}
    {!open && <button ref={launcher} type="button" className={styles.launcher} aria-label={open ? "Đóng trợ lý Zella" : "Mở trợ lý Zella"} aria-expanded={open} aria-controls="store-chat" onClick={() => setOpen(value => !value)}><span className={styles.launcherBot} aria-hidden="true"><BotAvatar type="mech" size={80} color="#bdbdbd" theme="light" interactive={false} paused={open} /></span></button>}
  </div>;
}
function Conversation({ onClose }: { onClose: () => void }) {
  const { status, user } = useAuth();
  const [messages, setMessages] = useState<Message[]>([welcome]);
  const [text, setText] = useState("");
  const [attachment, setAttachment] = useState<Message["image"]>();
  const [attachmentError, setAttachmentError] = useState("");
  const [readingFile, setReadingFile] = useState(false);
  const [pending, setPending] = useState(false);
  const [thinking, setThinking] = useState(false);
  const conversationId = useRef<string | undefined>(undefined);
  const inFlight = useRef<AbortController | null>(null);
  const mounted = useRef(false);
  useEffect(() => {
    mounted.current = true;
    return () => { mounted.current = false; inFlight.current?.abort(); };
  }, []);
  const isBusy = pending || thinking;

  async function askChat(question: string) {
    if (!mounted.current || inFlight.current || status !== "authenticated" || !user) return;
    const controller = new AbortController();
    inFlight.current = controller;
    setThinking(true);
    try {
      const result = await sendChatMessage(question, conversationId.current, controller.signal);
      if (!controller.signal.aborted) {
        conversationId.current = result.conversationId;
        setMessages(previous => [...previous, ...result.messages.map(message => ({ ...message, from: "bot" as const, streaming: !!message.text }))]);
      }
    } catch (error) {
      if (!controller.signal.aborted) {
        setMessages(previous => [...previous, {
          from: "bot", text: error instanceof Error ? error.message : "Không gửi được tin nhắn. Bạn thử lại nhé.",
          retryText: question,
        }]);
      }
    } finally {
      if (inFlight.current === controller) { inFlight.current = null; setThinking(false); }
    }
  }

  async function analyze(image: string) {
    if (!mounted.current || inFlight.current || status !== "authenticated" || !user) return;
    const controller = new AbortController();
    inFlight.current = controller;
    setPending(true);
    try {
      const result = await recognizeImage(image, controller.signal);
      if (!controller.signal.aborted) {
        setMessages(previous => [...previous, { from: "bot", text: describeRecognition(result), suggestions: result.suggestions, streaming: true }]);
      }
    } catch (error) {
      if (!controller.signal.aborted) {
        setMessages(previous => [...previous, {
          from: "bot",
          text: error instanceof Error ? error.message : "Không thể nhận diện ảnh. Vui lòng thử lại.",
          retryImage: image,
          streaming: true,
        }]);
      }
    } finally {
      if (inFlight.current === controller) { inFlight.current = null; setPending(false); }
    }
  }
  const fileInput = useRef<HTMLInputElement>(null);
  async function selectImage(event: ChangeEvent<HTMLInputElement>) {
    if (readingFile || isBusy) {
      event.target.value = "";
      return;
    }
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;
    setAttachmentError("");
    if (!["image/png", "image/jpeg"].includes(file.type) || !/\.(png|jpe?g)$/i.test(file.name)) {
      setAttachmentError("Vui lòng chọn ảnh PNG hoặc JPG."); return;
    }
    if (file.size > 5 * 1024 * 1024) { setAttachmentError("Ảnh tối đa 5 MB."); return; }
    setReadingFile(true);
    try {
      const bytes = new Uint8Array(await file.slice(0, 8).arrayBuffer());
      const png = [137, 80, 78, 71, 13, 10, 26, 10].every((byte, index) => bytes[index] === byte);
      const jpg = bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
      if (file.type === "image/png" ? !png : !jpg) throw new Error("invalid image");
      const url = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result));
        reader.onerror = () => reject(reader.error);
        reader.readAsDataURL(file);
      });
      setAttachment({ url, name: file.name });
    } catch { setAttachmentError("Không thể đọc ảnh. Vui lòng chọn ảnh PNG hoặc JPG hợp lệ."); }
    finally { setReadingFile(false); }
  }
  const log = useRef<HTMLDivElement>(null);
  const input = useRef<HTMLTextAreaElement>(null);
  useEffect(() => { if (log.current) log.current.scrollTop = log.current.scrollHeight; }, [messages, isBusy]);
  function send(value: string, displayText?: string) {
    if (status !== "authenticated" || !user || inFlight.current || readingFile || isBusy || (!value.trim() && !attachment)) return;
    const question = value.trim().slice(0, 1000);
    const currentAttachment = attachment;
    setText("");
    if (input.current) input.current.style.height = "auto";
    setAttachment(undefined);
    setAttachmentError("");
    input.current?.focus();

    if (currentAttachment) {
      setMessages(previous => [...previous, { from: "user", text: question, image: currentAttachment }]);
      void (async () => {
        await analyze(currentAttachment.url);
        if (question) await askChat(question);
      })();
    } else {
      setMessages(previous => [...previous, { from: "user", text: displayText ?? question }]);
      void askChat(question);
    }
  }
  function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); send(text); }
  return <>
    <div className={styles.chatToolbar}>
      <span>Tư vấn theo nhu cầu của bạn</span>
      <button type="button" disabled={isBusy || readingFile} onClick={() => {
        conversationId.current = undefined;
        setMessages([welcome]); setText(""); setAttachment(undefined); setAttachmentError("");
      }}>Trò chuyện mới</button>
    </div>
    <div ref={log} className={styles.messages} role="log" aria-label="Tin nhắn" aria-live="polite" aria-relevant="additions">
      {messages.map((message, index) => (
        <div key={index} className={`${styles.message} ${message.from === "user" ? styles.user : styles.bot}`}>
          <span className={styles.srOnly}>{message.from === "user" ? "Bạn" : "Zella"}:</span>
          {message.from === "bot" && (
            <div className={styles.replyAvatar} aria-hidden="true">
              <BotAvatar type="mech" size={32} color="#bdbdbd" theme="light" interactive={false} />
            </div>
          )}
          <div className={styles.messageContent}>
            {message.image && <img className={styles.sentImage} src={message.image.url} alt={message.image.name} />}
            {message.text && (
              <p className="normal-caption">
                {message.streaming ? (
                  <StreamingText
                    text={message.text}
                    onScroll={() => {
                      if (log.current) log.current.scrollTop = log.current.scrollHeight;
                    }}
                    onComplete={() => {
                      setMessages(previous =>
                        previous.map(item => (item === message ? { ...item, streaming: false } : item))
                      );
                    }}
                  />
                ) : (
                  message.text
                )}
              </p>
            )}
            {message.suggestions?.map((suggestion, group) => (
              <section key={group} className={styles.catalogGroup} aria-label={`Gợi ý ${suggestion.label}`}>
                {suggestion.products.length > 0 && <>
                  <strong>{garmentName(suggestion.label)}</strong>
                  <p>{suggestion.colorMatched ? "Có biến thể thuộc nhóm màu phù hợp còn hàng." : "Gợi ý cùng loại; chưa có màu khớp với ảnh."}</p>
                </>}
                {suggestion.products.map(product => (
                  <Link key={product.id} href={`/product/${encodeURIComponent(product.slug)}`} className={styles.catalogProduct} onNavigate={onClose}>
                    {product.imageUrl && <img src={product.imageUrl} alt={product.name} loading="lazy" />}
                    <span><strong>{product.name}</strong><span>{new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(product.salePrice ?? product.basePrice)}</span><span>Xem chi tiết →</span></span>
                  </Link>
                ))}
                <div className={styles.catalogActions}>
                  <Link href={catalogSearchUrl(suggestion.label)} onNavigate={onClose}>Xem {garmentName(suggestion.label)} khác <GoogleSymbol name="north_east" size={16} /></Link>
                  <button type="button" disabled={readingFile || isBusy} onClick={() => fileInput.current?.click()}>Tìm bằng ảnh khác <GoogleSymbol name="add_photo_alternate" size={17} /></button>
                </div>
              </section>
            ))}
            {message.botImage && <a className={styles.guideImage} href={message.botImage} target="_blank" rel="noopener noreferrer"><img src={message.botImage} alt="Bảng size hoặc hình ảnh từ cửa hàng" loading="lazy" /><span>Mở ảnh để xem rõ hơn</span></a>}
            {message.products && message.products.length > 0 && <section className={styles.catalogGroup} aria-label="Sản phẩm trong cửa hàng">
              {message.products.map(product => <div key={product.id}>
                <Link href={`/product/${encodeURIComponent(product.slug)}`} className={styles.catalogProduct} onNavigate={onClose}>
                  {product.imageUrl && <img src={product.imageUrl} alt={product.name} loading="lazy" />}
                  <span><strong>{product.name}</strong><span>{new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(product.price)}</span><span>Xem chi tiết →</span></span>
                </Link>
                <button className={styles.chatAction} type="button" disabled={readingFile || isBusy || !!attachment} onClick={() => send(`Tư vấn size sản phẩm ${product.slug}`)}>Tư vấn size mẫu này</button>
              </div>)}
            </section>}
            {message.sizeGuide && <section className={styles.sizeGuide} aria-label="Thông tin bảng size">
              <strong>{message.sizeGuide.product}</strong>
              {message.sizeGuide.sizes.length > 0 && <p>Kích cỡ được khai báo: {message.sizeGuide.sizes.join(", ")}.</p>}
              {message.sizeGuide.chartUrl && <a href={message.sizeGuide.chartUrl} target="_blank" rel="noopener noreferrer">Mở bảng size sản phẩm</a>}
            </section>}
            {!!message.buttons?.length && <div className={styles.quickReplies}>{message.buttons.map((button, buttonIndex) => <button key={buttonIndex} type="button" disabled={readingFile || isBusy || !!attachment} onClick={() => send(button.payload, button.title)}>{button.title}</button>)}</div>}
            {message.retryText && <button className={styles.retryButton} type="button" disabled={isBusy || readingFile} onClick={() => {
              if (inFlight.current) return;
              setMessages(previous => previous.filter(item => item !== message));
              void askChat(message.retryText!);
            }}>Gửi lại tin nhắn</button>}
            {message.retryImage && (
              <button
                type="button"
                className={styles.retryButton}
                disabled={isBusy}
                onClick={() => {
                  const image = message.retryImage;
                  if (!image || inFlight.current) return;
                  setMessages(previous => previous.filter(item => item !== message));
                  void analyze(image);
                }}
              >
                Thử lại
              </button>
            )}
          </div>
        </div>
      ))}
      {messages.length === 1 && <div className={styles.quickReplies} aria-label="Chủ đề tư vấn">{topics.map(topic => <button key={topic.label} type="button" disabled={readingFile || isBusy || !!attachment} onClick={() => send(topic.question)}>{topic.label}</button>)}</div>}
      {isBusy && (
        <div className={styles.processing} role="status">
          <div className={styles.replyAvatar} aria-hidden="true">
            <BotAvatar type="mech" state="working" size={32} color="#bdbdbd" theme="light" interactive={false} />
          </div>
          <span className={`${styles.thinkingText} normal-caption`}>{thinking ? "Zella đang trả lời…" : "Đang nhận diện ảnh…"}</span>
        </div>
      )}
    </div>
    <form className={styles.composer} onSubmit={submit}>
      {attachment && <div className={styles.attachment}><img src={attachment.url} alt={attachment.name} /><span>{attachment.name}</span><button type="button" aria-label="Bỏ ảnh đã chọn" onClick={() => setAttachment(undefined)}><GoogleSymbol name="close" size={16} /></button></div>}
      {attachmentError && <p className={styles.attachmentError} role="alert">{attachmentError}</p>}
      {readingFile && <p className={styles.fileStatus} role="status">Đang đọc ảnh…</p>}
      <input ref={fileInput} className={styles.fileInput} type="file" accept="image/png,image/jpeg,.png,.jpg,.jpeg" aria-label="Chọn ảnh PNG hoặc JPG" onChange={selectImage} disabled={readingFile || isBusy} />
      <textarea ref={input} rows={1} aria-label="Tin nhắn cho Zella" value={text} maxLength={1000} onChange={event => { setText(event.target.value); event.target.style.height = "auto"; event.target.style.height = `${Math.min(event.target.scrollHeight, 96)}px`; }} onKeyDown={event => { if (event.key === "Enter" && !event.shiftKey && !event.nativeEvent.isComposing) { event.preventDefault(); event.currentTarget.form?.requestSubmit(); } }} placeholder="Bạn đang tìm trang phục nào?" />
      <div className={styles.composerActions}>
        <button
          type="button"
          className={styles.addButton}
          disabled={readingFile || isBusy}
          aria-disabled={readingFile || isBusy}
          aria-label="Gửi ảnh PNG hoặc JPG"
          title={isBusy ? "Đang xử lý, vui lòng đợi…" : "Gửi ảnh PNG / JPG"}
          onClick={() => {
            if (readingFile || isBusy) return;
            fileInput.current?.click();
          }}
        >
          <GoogleSymbol name="add" size={21} />
        </button>
        <span className={styles.composerHint}>
          {pending ? "Đang phân tích ảnh…" : thinking ? "Đang suy nghĩ…" : "PNG, JPG · tối đa 5 MB"}
        </span>
        <button className={styles.sendButton} type="submit" disabled={isBusy || readingFile || (!text.trim() && !attachment)} aria-label="Gửi tin nhắn"><GoogleSymbol name="arrow_upward" size={20} /></button>
      </div>
    </form>
  </>;
}
