import { createFileRoute, useParams } from "@tanstack/react-router";
import { MatchSummaryView } from "~components/MatchSummaryView";

export const MatchSummaryPage: React.FC = () => {
  const { matchId: matchIdParam } = useParams({ from: "/$sku/match/$matchId" });
  const initialMatchId = parseInt(matchIdParam, 10);

  return <MatchSummaryView initialMatchId={initialMatchId} />;
};

export const Route = createFileRoute("/$sku/match/$matchId")({
  component: MatchSummaryPage,
});
