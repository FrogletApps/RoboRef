import type QrCreator from "qr-creator";
import { useEffect, useRef } from "react";
import { twMerge } from "tailwind-merge";
import { createUltraHDRJpeg } from "~utils/ultrahdr";

export type QRCodeProps = React.HTMLProps<HTMLDivElement> & {
  config: QrCreator.Config;
  isHDR?: boolean;
};

export const QRCode: React.FC<QRCodeProps> = ({
  config,
  isHDR,
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

    let createdBlobUrl: string | null = null;

    import("qr-creator").then(({ default: QrCreator }) => {
      if (!isMounted || !container) return;
      container.replaceChildren();

      const { width } = container.getBoundingClientRect();
      const size = width > 0 ? width : config.size ?? 128;

      QrCreator.render({ size, ...config }, container);

      if (isHDR) {
        const canvas = container.querySelector("canvas");
        if (canvas) {
          try {
            createdBlobUrl = createUltraHDRJpeg(canvas);
            const img = document.createElement("img");
            img.src = createdBlobUrl;
            img.alt = "Ultra HDR QR Code";
            img.className = "w-full h-full object-contain";
            container.replaceChildren(img);
          } catch (e) {
          }
        }
      }
    });

    return () => {
      isMounted = false;
      if (createdBlobUrl) {
        URL.revokeObjectURL(createdBlobUrl);
      }
    };
  }, [config, isHDR]);

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
