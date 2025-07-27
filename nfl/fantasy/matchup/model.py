from dataclasses import dataclass

@dataclass
class Matchup:
    sleeper_id_x: str
    score_x: str
    sleeper_id_y: str
    score_y: str
    week: int

@dataclass
class Season:
    id: str
    league_id: str