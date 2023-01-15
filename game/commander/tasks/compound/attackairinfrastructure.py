from collections.abc import Iterator
from dataclasses import dataclass

from game.commander.tasks.primitive.oca import PlanOcaStrike
from game.commander.theaterstate import TheaterState
from game.htn import CompoundTask, Method
from game.settings import Settings


@dataclass(frozen=True)
class AttackAirInfrastructure(CompoundTask[TheaterState]):
    settings: Settings

    def each_valid_method(self, state: TheaterState) -> Iterator[Method[TheaterState]]:
        for battle_position in state.oca_targets:
            yield [PlanOcaStrike(battle_position, self.settings)]
