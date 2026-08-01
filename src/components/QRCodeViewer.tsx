import React from "react";
import { QRCode } from "~components/QRCode";
import { ClickToCopy } from "~components/ClickToCopy";
import { Select } from "~components/Input";
import { useQRCodeMode, QRCodeMode } from "~utils/hooks/qr";
import { twMerge } from "tailwind-merge";

export type QRCodeViewerProps = React.HTMLProps<HTMLDivElement> & {
  text: string;
};

export const QRCodeViewer: React.FC<QRCodeViewerProps> = ({
  text,
  className,
  ...props
}) => {
  const { mode, setMode } = useQRCodeMode();

  const qrConfig = React.useMemo(() => {
    if (mode === "stylised") {
      return {
        text,
        radius: 0.4,
        ecLevel: "H" as const,
        fill: "#10b981",
        background: null,
      };
    }
    return {
      text,
      radius: 0,
      ecLevel: "H" as const,
      fill: "#000000",
      background: "#ffffff",
    };
  }, [text, mode]);

  const toggleMode = React.useCallback(() => {
    if (mode === "stylised") {
      setMode("standard");
    } else {
      setMode("stylised");
    }
  }, [mode, setMode]);

  return (
    <div
      {...props}
      className={twMerge(
        "bg-zinc-900 border border-zinc-800 p-6 rounded-2xl shadow-xl flex flex-col items-center gap-5 w-full max-w-sm",
        className
      )}
    >
      <div className="w-full flex flex-col gap-1.5">
        <label htmlFor="qr-mode-select" className="text-xs font-medium text-zinc-400">
          Style Options
        </label>
        <Select<QRCodeMode>
          id="qr-mode-select"
          value={mode}
          onChange={(e) => setMode(e.currentTarget.value as QRCodeMode)}
          className="w-full text-sm bg-zinc-800 border border-zinc-700/60 text-zinc-100 focus:ring-emerald-500"
        >
          <option value="stylised">Stylised</option>
          <option value="standard">Standard</option>
          <option value="hdr">HDR</option>
        </Select>
      </div>

      <div className="flex flex-col items-center gap-2 w-full">
        <button
          type="button"
          onClick={toggleMode}
          aria-label="Toggle QR Code style"
          className={twMerge(
            "w-64 h-64 p-4 rounded-xl flex items-center justify-center transition-all cursor-pointer focus:outline-none focus:ring-2 focus:ring-emerald-500",
            mode === "stylised"
              ? "bg-zinc-800/80 border border-zinc-700/50"
              : "bg-white border border-zinc-200",
            mode === "hdr" && "bg-white"
          )}
        >
          <QRCode
            config={qrConfig}
            isHDR={mode === "hdr"}
            className={twMerge(
              "w-full h-full p-0",
              mode === "stylised" ? "bg-transparent" : "bg-white"
            )}
          />
        </button>

        {mode === "hdr" && (
          <p className="text-xs text-zinc-400 text-center max-w-xs leading-tight">
            HDR will only fully work on supported browsers on supported devices
          </p>
        )}
      </div>

      <div className="w-full flex flex-col gap-3">
        <ClickToCopy message={text} className="w-full justify-center text-center" />
      </div>
    </div>
  );
};
