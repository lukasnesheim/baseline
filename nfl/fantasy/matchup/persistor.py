# function imports
from model import Matchup, Season
from supabase import Client

def get_club_ids(client: Client, league_id: str) -> dict[str, str] | None:
    try:
        # query club records
        response = client.table("club").select("id, external").eq("league", league_id).eq("active", True).execute()

        if not response.data:
            print(f"No club records returned for league id: {league_id}.")
            return None
        
        # return the lookup dictionary of club ids
        return { record["external"]: record["id"] for record in response.data }
    
    except Exception as ex:
        print(f"Querying Supabase database failed.\nException {ex}")
        return None
    
def get_season(client: Client, sleeper_league_id: str) -> Season | None:
    try:
        # query season records
        response = client.table("season").select("*").eq("external", sleeper_league_id).execute()  
        
        if not response.data:
            print(f"No season record returned for sleeper league id: {sleeper_league_id}.")
            return None
        
        # return the first season record
        return Season(id = response.data[0]["id"], league_id = response.data[0]["league"])

    except Exception as ex:
        print(f"Querying Supabase database failed.\nException: {ex}")
        return None

def insert_matchups(client: Client, season_id: str, matchups: list[Matchup], club_ids: dict[str, str]) -> bool:
    try:
        records = [{
            "season": season_id,
            "club_x": club_ids[m.sleeper_id_x],
            "score_x": m.score_x,
            "club_y": club_ids[m.sleeper_id_y],
            "score_y": m.score_y,
            "winner": club_ids[m.sleeper_id_x] if m.score_x > m.score_y else club_ids[m.sleeper_id_y] if m.score_y > m.score_x else None,
            "week": m.week
        } for m in matchups]
        
        response = client.table("matchup").insert(records).execute()
        
        if not response.data or response.data.count != matchups.count:
            raise RuntimeError(f"No response data returned by the Supabase client.")
        
        if response.data.count != matchups.count:
            raise RuntimeError(f"Only {response.data.count} records were inserted when {matchups.count} were expected.")

        return True
    
    except Exception as ex:
        return False