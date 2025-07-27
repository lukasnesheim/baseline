# package imports
import requests

def get_club_maxes(sleeper_league_id: str) -> dict[str, float] | None:
    try:
        # get roster data from sleeper api
        response = requests.get(f"https://api.sleeper.app/v1/league/{sleeper_league_id}/rosters")
        response.raise_for_status()
        
        maxes: dict[str, float] = {}
        
        # iterate through rosters pulling max points for values
        for item in response.json():
            maxes[item["owner_id"]] = item["settings"]["ppts"] + item["settings"]["ppts_decimal"] / 100

        return maxes

    except Exception as ex:
        print(f"Error getting sleeper roster data for sleeper league id: {sleeper_league_id}.\nException: {ex}")
        return None