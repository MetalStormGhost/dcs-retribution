from __future__ import annotations

from dataclasses import dataclass
from random import randint

from game.ato.flighttype import FlightType
from game.commander.tasks.packageplanningtask import PackagePlanningTask
from game.commander.theaterstate import TheaterState
from game.settings import Settings
from game.theater import ControlPoint


@dataclass
class PlanOcaStrike(PackagePlanningTask[ControlPoint]):
    settings: Settings

    def preconditions_met(self, state: TheaterState) -> bool:
        if self.target not in state.oca_targets:
            return False
        if not self.target_area_preconditions_met(state):
            return False
        return super().preconditions_met(state)

    def apply_effects(self, state: TheaterState) -> None:
        state.oca_targets.remove(self.target)

    def propose_flights(self) -> None:
        from game.ato.starttype import StartType

        self.propose_flight(FlightType.OCA_RUNWAY, randint(2, 4))
        if self.settings.default_start_type is StartType.COLD:
            self.propose_flight(FlightType.OCA_AIRCRAFT, 2)
        self.propose_common_escorts()
        if self.settings.autoplan_tankers_for_oca:
            self.propose_flight(FlightType.REFUELING, 1)
