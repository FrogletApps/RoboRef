import { createFileRoute } from "@tanstack/react-router";
import PrivacyPolicy from "../../documents/privacy.md";

import "./markdown.css";

const PrivacyPage: React.FC = () => {
  return (
    <main className="w-full max-w-full md:max-w-3xl lg:max-w-4xl mx-auto px-2 sm:px-4 py-6 overflow-y-auto overflow-x-hidden min-w-0 flex-1 markdown">
      <PrivacyPolicy />
    </main>
  );
};

export const Route = createFileRoute("/privacy")({
  component: PrivacyPage,
});
