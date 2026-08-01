import React, { createContext, useContext, useEffect, useState } from "react";

export type QRCodeMode = "stylised" | "standard" | "hdr";

type QRCodeContextType = {
  mode: QRCodeMode;
  setMode: (mode: QRCodeMode) => void;
};

const QRCodeContext = createContext<QRCodeContextType | undefined>(undefined);

const STORAGE_KEY = "meta#qr_code_mode";

export const QRCodeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [mode, setModeState] = useState<QRCodeMode>(() => {
    if (typeof window === "undefined") return "stylised";
    const saved = localStorage.getItem(STORAGE_KEY) as QRCodeMode | null;
    if (saved && (saved === "stylised" || saved === "standard" || saved === "hdr")) {
      return saved;
    }
    return "stylised";
  });

  const setMode = (newMode: QRCodeMode) => {
    setModeState(newMode);
    localStorage.setItem(STORAGE_KEY, newMode);
  };

  useEffect(() => {
    const handleStorage = (e: StorageEvent) => {
      if (e.key === STORAGE_KEY && e.newValue) {
        const val = e.newValue as QRCodeMode;
        if (val === "stylised" || val === "standard" || val === "hdr") {
          setModeState(val);
        }
      }
    };
    window.addEventListener("storage", handleStorage);
    return () => window.removeEventListener("storage", handleStorage);
  }, []);

  return (
    <QRCodeContext.Provider value={{ mode, setMode }}>
      {children}
    </QRCodeContext.Provider>
  );
};

export const useQRCodeMode = (): QRCodeContextType => {
  const context = useContext(QRCodeContext);
  if (!context) {
    throw new Error("useQRCodeMode must be used within a QRCodeProvider");
  }
  return context;
};
