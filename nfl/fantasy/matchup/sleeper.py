# package imports
import requests

# function imports
from collections import defaultdict
from model import Matchup
from typing import Any

def match_rosters_to_matchups(matchups: list[dict[str, Any]], rosters: list[dict[str, Any]], week: int) -> list[Matchup] | None:
    try:
        roster_sets: list[tuple[str, set[str]]] = []
        for roster in rosters:
            roster_sets.append((roster["owner_id"], set(roster["players"])))

        matchup_groups: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)
        for matchup in matchups:
            matchup_groups[matchup["matchup_id"]].append(matchup)

        identified_matchups: list[Matchup] = []

        for matchup_id, teams in matchup_groups.items():
            if not matchup_id:
                continue

            team_x, team_y = teams

            players_x = set(team_x["players"])
            players_y = set(team_y["players"])

            sleeper_id_x = ""
            sleeper_id_y = ""

            for sleeper_id, roster_players in roster_sets:
                if sleeper_id_x and sleeper_id_y:
                    break
                elif not sleeper_id_x and len(players_x & roster_players) / len(players_x) >= 0.35:
                    sleeper_id_x = sleeper_id
                elif not sleeper_id_y and len(players_y & roster_players) / len(players_y) >= 0.35:
                    sleeper_id_y = sleeper_id

            # append the identified matchup
            if sleeper_id_x and sleeper_id_y:
                identified_matchups.append(Matchup(sleeper_id_x, team_x["points"], sleeper_id_y, team_y["points"], week))
            else:
                raise RuntimeError(f"Rosters were not found for matchup id: {matchup_id}. Adjust the threshold.")
        
        # check for uniqueness
        sleeper_ids = [im.sleeper_id_x for im in identified_matchups] + [im.sleeper_id_y for im in identified_matchups]
        
        if len(sleeper_ids) != len(set(sleeper_ids)):
            raise RuntimeError(f"The same sleeper owner id was assigned to multiple matchup participant rosters.")

        return identified_matchups
    
    except Exception as ex:
        print(f"Failed to match rosters to matchups.\nException: {ex}")
        return None

def get_matchups(sleeper_league_id: str, week: int) -> list[dict[str, Any]] | None:
    try:
        # get matchup data from sleeper api
        response = requests.get(f"https://api.sleeper.app/v1/league/{sleeper_league_id}/matchups/{week}")
        response.raise_for_status()
    
        return response.json()

    except Exception as ex:
        print(f"Error getting sleeper matchup data for sleeper league id: {sleeper_league_id} and week: {week}.\nException: {ex}")
        return None
    
def get_rosters(sleeper_league_id: str) -> list[dict[str, Any]] | None:
    try:
        # get roster data from sleeper api
        response = requests.get(f"https://api.sleeper.app/v1/league/{sleeper_league_id}/rosters")
        response.raise_for_status()

        return response.json()
    
    except Exception as ex:
        print(f"Error getting sleeper roster data for sleeper league id: {sleeper_league_id}.\nException: {ex}")
        return None
    
