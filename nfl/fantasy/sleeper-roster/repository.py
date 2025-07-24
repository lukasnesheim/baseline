# function imports
from model import Season
from supabase import Client

def get_season_by_sleeper_season_id(client: Client, sleeper_season_id: str) -> tuple[bool, Season | None]:
    try:
        # query season records
        response = client.table("season").select("*").eq("external", sleeper_season_id).execute()  
        if not response.data:
            return True, None
        
        # take the first season record
        return True, Season(id = response.data[0]["id"], league_id = response.data[0]["league"])

    except Exception as ex:
        print(f"Querying Supabase database failed.\nException: {ex}")
        return False, None

def upsert_podium_max(client: Client, season: Season, maxes: dict[str, float]) -> bool:
    try:
        # query podium records
        response = client.table("podium").select("*, club(id, external)").eq("season", season.id).execute()
        if not response.data:
            raise RuntimeError(f"No podium records found for season id: {season.id}.")
        
        podium_maxes = []

        # iterate through podium records
        for podium in response.data:
            if (max := maxes.get(podium["club"]["external"])):
                podium_maxes.append({"id": podium["id"], "season": season.id, "club": podium["club"]["id"], "max": max})

        # upsert podium records
        response = client.table("podium").upsert(podium_maxes).execute()

        return True
    
    except Exception as ex:
        print(f"Querying Supabase database failed.\nException: {ex}")
        return False