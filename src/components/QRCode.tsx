import type QrCreator from "qr-creator";
import { useEffect, useRef } from "react";
import { twMerge } from "tailwind-merge";

export type QRCodeProps = React.HTMLProps<HTMLDivElement> & {
  config: QrCreator.Config;
};

export const QRCode: React.FC<QRCodeProps> = ({
  config,
  className,
  ...props
}) => {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!ref.current) {
      return;
    }

    let isMounted = true;
    const container = ref.current;

    import("qr-creator").then(({ default: QrCreator }) => {
      if (!isMounted || !container) return;
      container.replaceChildren();

      const { width } = container.getBoundingClientRect();
      const size = width > 0 ? width : config.size ?? 128;

      QrCreator.render({ size, ...config }, container);
    });

    return () => {
      isMounted = false;
    };
  }, [config]);

  return (
    <div
      {...props}
      className={twMerge(
        "bg-white p-4 rounded-md flex items-center justify-center aspect-square",
        className
      )}
    >
      <div ref={ref} className="w-full h-full flex items-center justify-center" />
    </div>
  );
};
