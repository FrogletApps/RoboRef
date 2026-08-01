import { createFileRoute } from "@tanstack/react-router";
import { QRCodeViewer } from "~components/QRCodeViewer";
import AppIcon from "/icons/roboref.svg?url";

export const SharePage: React.FC = () => {
  return (
    <main className="max-w-md w-full mx-auto flex-1 pt-6 px-4 pb-4 flex flex-col items-center justify-start gap-6 overflow-y-auto">
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

      <QRCodeViewer text="https://roboref.fyi" />
    </main>
  );
};

export const Route = createFileRoute("/share")({
  component: SharePage,
});
