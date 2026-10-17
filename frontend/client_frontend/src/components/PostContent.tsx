import { Fragment, type CSSProperties, type ReactNode } from "react";
import styles from "./PostContent.module.css";

const PREFIX = "zella-quill-v1:";
type Attributes = { bold?: boolean; italic?: boolean; underline?: boolean; strike?: boolean; link?: string; header?: number; list?: string; blockquote?: boolean; align?: string; indent?: number };
type Op = { insert: string | { image: string }; attributes?: Attributes };
type Line = { children: ReactNode[]; attributes: Attributes };
function safeUrl(value: unknown): string | undefined {
    if (typeof value !== "string") return;
    try { const url = new URL(value); if (["https:", "http:"].includes(url.protocol) && !url.username && !url.password) return url.href; } catch { /* Invalid URLs render without a link or image. */ }
}
function inline(text: string, attr: Attributes, key: number): ReactNode {
    let node: ReactNode = text;
    if (attr.bold) node = <strong>{node}</strong>;
    if (attr.italic) node = <em>{node}</em>;
    if (attr.underline) node = <u>{node}</u>;
    if (attr.strike) node = <s>{node}</s>;
    const href = safeUrl(attr.link);
    if (href) node = <a href={href} target="_blank" rel="noopener noreferrer">{node}</a>;
    return <Fragment key={key}>{node}</Fragment>;
}
export default function PostContent({ content }: { content: string }) {
    if (!content.startsWith(PREFIX)) return <div className={styles.content} style={{ whiteSpace: "pre-wrap" }}>{content}</div>;
    let ops: Op[];
    try { ops = JSON.parse(content.slice(PREFIX.length)); if (!Array.isArray(ops)) throw new Error(); }
    catch { return <p role="alert">Không thể hiển thị nội dung bài viết.</p>; }
    const lines: Line[] = [];
    let children: ReactNode[] = [];
    let key = 0;
    for (const op of ops) {
        if (!op || typeof op !== "object") continue;
        const attr = op.attributes && typeof op.attributes === "object" ? op.attributes : {};
        if (typeof op.insert === "string") {
            const parts = op.insert.split("\n");
            parts.forEach((part, index) => {
                if (part) children.push(inline(part, attr, key++));
                if (index < parts.length - 1) { lines.push({ children, attributes: attr }); children = []; }
            });
        } else if (op.insert && typeof op.insert === "object") {
            const url = safeUrl(op.insert.image);
            // Images are rendered from the cloud URL, with no HTML interpolation.
            // eslint-disable-next-line @next/next/no-img-element
            if (url) children.push(<img key={key++} src={url} alt="Ảnh minh họa bài viết" loading="lazy" />);
        }
    }
    if (children.length) lines.push({ children, attributes: {} });
    const blocks: ReactNode[] = [];
    let list: ReactNode[] = [];
    let listType: string | undefined;
    const flushList = () => {
        if (!list.length) return;
        blocks.push(listType === "ordered" ? <ol key={`list-${blocks.length}`}>{list}</ol> : <ul key={`list-${blocks.length}`}>{list}</ul>);
        list = []; listType = undefined;
    };
    for (const [index, line] of lines.entries()) {
        const attr = line.attributes;
        const align = ["left", "center", "right", "justify"].includes(attr.align ?? "") ? attr.align as CSSProperties["textAlign"] : undefined;
        const indent = typeof attr.indent === "number" && Number.isFinite(attr.indent) ? Math.max(0, Math.min(8, attr.indent)) : 0;
        const style: CSSProperties = { textAlign: align, marginInlineStart: indent ? `${indent * 1.5}em` : undefined };
        const body = line.children.length ? line.children : <br />;
        if (["ordered", "bullet"].includes(attr.list ?? "")) {
            if (listType !== attr.list) flushList();
            listType = attr.list;
            list.push(<li key={index} style={style}>{body}</li>);
            continue;
        }
        flushList();
        if (attr.header === 1) blocks.push(<h1 key={index} style={style}>{body}</h1>);
        else if (attr.header === 2) blocks.push(<h2 key={index} style={style}>{body}</h2>);
        else if (attr.header === 3) blocks.push(<h3 key={index} style={style}>{body}</h3>);
        else if (attr.header === 4) blocks.push(<h4 key={index} style={style}>{body}</h4>);
        else if (attr.header === 5) blocks.push(<h5 key={index} style={style}>{body}</h5>);
        else if (attr.header === 6) blocks.push(<h6 key={index} style={style}>{body}</h6>);
        else if (attr.blockquote) blocks.push(<blockquote key={index} style={style}>{body}</blockquote>);
        else blocks.push(<p key={index} style={style}>{body}</p>);
    }
    flushList();
    return <div className={styles.content}>{blocks}</div>;
}
