import { createFileRoute } from "@tanstack/react-router";

const ContactPage: React.FC = () => {
  return (
    <main className="max-w-xl h-full w-full mx-auto flex-1 pb-6 overflow-y-auto">
      <section className="mt-4">
        <p className="text-zinc-300">
          If you want to get in touch please email us at{" "}
          <a
            className="text-emerald-400 underline"
            href={`mailto:hello@roboref.fyi?subject=${encodeURIComponent(
              `RoboRef Version ${__ROBOREF_VERSION__}`
            )}`}
          >
            hello@roboref.fyi
          </a>
          .
        </p>
        <br />
        <p className="text-zinc-400">
          For bug reports please include as much information as possible, for example what you were trying to do in the app, what happened, when it happened, and what event you're at. If possible include screenshots to help us see what's happening.
        </p>
      </section>
    </main>
  );
};

export const Route = createFileRoute("/contact")({
  component: ContactPage,
});
