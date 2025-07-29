# package imports
import os
import polars as pl

# function imports
from dotenv import load_dotenv
from supabase import Client, create_client

load_dotenv()

sleeper_league_id: str = os.getenv("HOMIES_2024") or ""
if not sleeper_league_id:
    raise ValueError("Failed to retrieve environment variable for sleeper league id.")

supabase_url: str = os.getenv("SUPABASE_URL") or ""
if not supabase_url:
    raise ValueError("Failed to retrieve environment variable for supabase url.")

supabase_key: str = os.getenv("SUPABASE_KEY") or ""
if not supabase_key:
    raise ValueError("Failed to retrieve environment variable for supabase key.")

try:
    client: Client = create_client(supabase_url, supabase_key)

    season_id: str = client.table("season").select("id").eq("external", sleeper_league_id).execute().data[0]["id"]
    if not season_id:
        raise RuntimeError(f"No season record returned for the sleeper league id: {sleeper_league_id}.")
    
    response = client.table("podium").select("*, club(id, name)").eq("season", season_id).execute()
    if not response.data:
        raise RuntimeError(f"No podium records returned for the season id: {season_id}.")
    
    podiums = [
        {
            "club_name": row["club"]["name"],
            "rank": row["regular"],
            "win": row["win_regular"],
            "loss": row["loss_regular"],
            "draw": row["draw_regular"],
            "pf": row["for"],
            "pa": row["against"],
            "max": row["max"]
        }
        for row in response.data
    ]

    df = pl.DataFrame(podiums).sort("rank")
    df.write_csv("podiums.csv")

except Exception as ex:
    print(f"Exception: {ex}")