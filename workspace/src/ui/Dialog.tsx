import { useEffect, useRef, type ReactNode } from "react";
import { Icon } from "./Icon";

export function Dialog({
  title,
  onClose,
  children,
  footer,
  width,
}: {
  title: string;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
  width?: number;
}) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (el && !el.open) el.showModal();
    const onCancel = (e: Event) => {
      e.preventDefault();
      onClose();
    };
    el?.addEventListener("cancel", onCancel);
    return () => el?.removeEventListener("cancel", onCancel);
  }, [onClose]);

  return (
    <dialog
      ref={ref}
      style={width ? { width: `min(${width}px, calc(100vw - 32px))` } : undefined}
      onClick={(e) => {
        if (e.target === ref.current) onClose();
      }}
    >
      <div className="dlg-h">
        <h3>{title}</h3>
        <button type="button" className="btn icon ghost" onClick={onClose} aria-label="Close">
          <Icon name="x" />
        </button>
      </div>
      <div className="dlg-b">{children}</div>
      {footer && <div className="dlg-f">{footer}</div>}
    </dialog>
  );
}
