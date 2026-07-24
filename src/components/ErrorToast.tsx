import { Error } from "./Warning";
import { LinkButton } from "./Button";
import { BugAntIcon } from "@heroicons/react/20/solid";
import { ToastArguments } from "./Toast";
import { twMerge } from "tailwind-merge";

export type ErrorToastProps = Omit<ToastArguments, "type"> &
  React.HTMLProps<HTMLDivElement>;

export const ErrorToast: React.FC<ErrorToastProps> = ({
  message,
  context,
  ...props
}) => {
  return (
    <section
      {...props}
      className={twMerge("flex gap-2 items-center", props.className)}
    >
      <Error message={message + "\n" + context} />
      <LinkButton
        to="/contact"
        aria-label="Contact Developer"
        className="aspect-square h-10 w-10 text-red-950 bg-red-300 flex items-center justify-center p-0"
      >
        <BugAntIcon height={20} />
      </LinkButton>
    </section>
  );
};
