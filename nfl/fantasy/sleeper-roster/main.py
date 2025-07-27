# package imports
import os
import sys

# function imports
from dotenv import load_dotenv
from repository import get_season_by_sleeper_league_id, upsert_podium_max
from sleeper import get_club_maxes
from supabase import create_client, Client

# load environment variables
load_dotenv()

# global variables
sleeper_league_id: str = os.getenv("HOMIES_2024") or ""
if not sleeper_league_id:
    raise ValueError("Failed to retrieve environment variable for sleeper season id.")

supabase_url: str = os.getenv("SUPABASE_URL") or ""
if not supabase_url:
    raise ValueError("Failed to retrieve environment variable for supabase url.")

supabase_key: str = os.getenv("SUPABASE_KEY") or ""
if not supabase_key:
    raise ValueError("Failed to retrieve environment variable for supabase key.")

# get club max points for values from sleeper
maxes = get_club_maxes(sleeper_league_id)
if maxes is None:
    sys.exit()

elif not maxes:
    print(f"No max values returned. Skipping updates and exiting.")
    sys.exit()

# create the supabase client
client: Client = create_client(supabase_url, supabase_key)

# get season from supabase
success, season = get_season_by_sleeper_league_id(client, sleeper_league_id)
if not success:
    sys.exit()

elif season is None:
    print(f"No season record returned for sleeper league id: {sleeper_league_id}.")
    sys.exit()

# update supabase podium records with max points for values from sleeper
upsert_podium_max(client, season, maxes)