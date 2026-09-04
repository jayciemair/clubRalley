import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

/* Safe by default: react-markdown does NOT render raw HTML unless you add
   rehype-raw (we don't). Links open in a new tab with noopener. */
export function MarkdownView({ children }: { children: string }) {
  return (
    <div className="md">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{
          a: ({ href, children }) => (
            <a href={href} target="_blank" rel="noopener noreferrer nofollow">
              {children}
            </a>
          ),
        }}
      >
        {children || "_Empty page — hit Edit to add something._"}
      </ReactMarkdown>
    </div>
  );
}
