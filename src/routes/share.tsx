import { createFileRoute } from "@tanstack/react-router";
import { QRCode } from "~components/QRCode";
import { ClickToCopy } from "~components/ClickToCopy";
import AppIcon from "/icons/roboref.svg?url";

export const SharePage: React.FC = () => {
  return (
    <main className="max-w-md w-full mx-auto flex-1 p-4 flex flex-col items-center justify-center gap-6 overflow-y-auto">
      <div className="flex flex-col items-center gap-2 text-center">
        <div className="flex items-center gap-3">
          <img src={AppIcon} alt="RoboRef Logo" className="w-10 h-10 object-contain" />
          <h1 className="text-3xl font-bold font-mono tracking-tight">
            <span className="text-zinc-100">RoboRef</span>
            <span className="text-zinc-400">.fyi</span>
          </h1>
        </div>
        <p className="text-zinc-400 text-sm mt-1">
          Scan the QR code below or share the link
        </p>
      </div>

      <div className="bg-zinc-900 border border-zinc-800 p-6 rounded-2xl shadow-xl flex flex-col items-center gap-5 w-full max-w-sm">
        <div className="w-64 h-64 bg-zinc-800/80 p-4 rounded-xl border border-zinc-700/50 flex items-center justify-center">
          <QRCode
            config={{
              text: "https://roboref.fyi",
              radius: 0.4,
              ecLevel: "H",
              fill: "#10b981",
              background: null,
            }}
            className="w-full h-full p-0 bg-transparent"
          />
        </div>
        <div className="w-full flex flex-col gap-3">
          <ClickToCopy message="https://roboref.fyi" className="w-full justify-center text-center" />
        </div>
      </div>
    </main>
  );
};

export const Route = createFileRoute("/share")({
  component: SharePage,
});
