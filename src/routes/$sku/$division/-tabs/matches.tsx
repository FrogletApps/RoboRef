import { EventData } from "@referee-fyi/robotevents";
import { MatchSummaryView } from "~components/MatchSummaryView";

export type EventMatchesTabProps = {
  event: EventData;
  initialMatchId?: number;
};

export const EventMatchesTab: React.FC<EventMatchesTabProps> = ({
  event,
  initialMatchId,
}) => {
  return (
    <MatchSummaryView
      event={event}
      initialMatchId={initialMatchId}
      key={initialMatchId}
    />
  );
};
