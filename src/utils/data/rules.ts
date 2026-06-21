import { programs, seasons } from "@referee-fyi/robotevents";
import { Game } from "~utils/hooks/rules";

import LevelUp from "/rules/VIQRC/2026-2027.json?url";
import Override from "/rules/V5RC/2026-2027.json?url";

import PushBack from "/rules/V5RC/2025-2026.json?url";
import MixAndMatch from "/rules/VIQRC/2025-2026.json?url";

import HighStakes from "/rules/V5RC/2024-2025.json?url";
import RapidRelay from "/rules/VIQRC/2024-2025.json?url";

import OverUnder from "/rules/V5RC/2023-2024.json?url";
import FullVolume from "/rules/VIQRC/2023-2024.json?url";

// 2026-2027
export const LevelUpRules: () => Promise<Game> = async () =>
  fetch(LevelUp).then((res) => res.json());

export const OverrideRules: () => Promise<Game> = async () =>
  fetch(Override).then((res) => res.json());

// 2025-2026
export const PushBackRules: () => Promise<Game> = async () =>
  fetch(PushBack).then((res) => res.json());

export const MixAndMatchRules: () => Promise<Game> = async () =>
  fetch(MixAndMatch).then((res) => res.json());

// 2024-2025
export const HighStakesRules: () => Promise<Game> = async () =>
  fetch(HighStakes).then((res) => res.json());

export const RapidRelayRules: () => Promise<Game> = async () =>
  fetch(RapidRelay).then((res) => res.json());

// 2023-2024
export const OverUnderRules: () => Promise<Game> = async () =>
  fetch(OverUnder).then((res) => res.json());

export const FullVolumeRules: () => Promise<Game> = async () =>
  fetch(FullVolume).then((res) => res.json());

// Supported games
export const GAME_FETCHERS: Record<number, () => Promise<Game>> = {
  // 2026-2027
  // The bundled `robotevents` package predates this season, so its
  // `seasons[program]` maps have no "2026-2027" key. Use the literal
  // events.vex.com season ids until the package is updated.
  203: LevelUpRules, // VIQRC Level Up
  204: OverrideRules, // V5RC Override
  205: OverrideRules, // VURC Override
  206: OverrideRules, // VAIRC Override

  // 2025-2026
  // Same caveat as above: the bundled `robotevents` package has no
  // "2025-2026" key, so use the literal events.vex.com season ids.
  197: PushBackRules, // V5RC Push Back
  198: PushBackRules, // VURC Push Back
  199: PushBackRules, // VAIRC Push Back
  196: MixAndMatchRules, // VIQRC Mix & Match

  // 2024-2025
  [seasons[programs.V5RC]["2024-2025"]]: HighStakesRules,
  [seasons[programs.VURC]["2024-2025"]]: HighStakesRules,
  [seasons[programs.VAIRC]["2024-2025"]]: HighStakesRules,
  [seasons[programs.VIQRC]["2024-2025"]]: RapidRelayRules,

  // 2023-2024
  [seasons[programs.V5RC]["2023-2024"]]: OverUnderRules,
  [seasons[programs.VURC]["2023-2024"]]: OverUnderRules,
  [seasons[programs.VAIRC]["2023-2024"]]: OverUnderRules,
  [seasons[programs.VIQRC]["2023-2024"]]: FullVolumeRules,
};
