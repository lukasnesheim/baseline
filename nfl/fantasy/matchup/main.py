# package imports
import os
import sys

# function imports
from dotenv import load_dotenv
from persistor import get_club_ids, get_season, insert_matchups
from sleeper import match_rosters_to_matchups, get_matchups, get_rosters
from supabase import Client, create_client

# load environment variables
load_dotenv()

# global variables
sleeper_league_id: str = os.getenv("HOMIES_2025") or ""
if not sleeper_league_id:
    raise ValueError("Failed to retrieve environment variable for sleeper season id.")

supabase_url: str = os.getenv("SUPABASE_URL") or ""
if not supabase_url:
    raise ValueError("Failed to retrieve environment variable for supabase url.")

supabase_key: str = os.getenv("SUPABASE_KEY") or ""
if not supabase_key:
    raise ValueError("Failed to retrieve environment variable for supabase key.")

# parameters
week: int = 1

# get matchups
matchups = get_matchups(sleeper_league_id, week)

if matchups is None:
    sys.exit()

elif not matchups:
    print(f"No matchups returned. Skipping updates and exiting.")
    sys.exit()

# get rosters
rosters = get_rosters(sleeper_league_id)

if rosters is None:
    sys.exit()

elif not rosters:
    print(f"No rosters returned. Skipping updates and exiting.")
    sys.exit()

# match rosters to matchup participants
roster_matchups = match_rosters_to_matchups(matchups, rosters, week)

if roster_matchups is None or not roster_matchups:
    sys.exit()

# create the supabase client
client: Client = create_client(supabase_url, supabase_key)

# get season from supabase
season = get_season(client, sleeper_league_id)

if season is None:
    sys.exit()

# get club id lookup dictionary
club_ids = get_club_ids(client, season.league_id)

if club_ids is None:
    sys.exit()

# insert matchups to the Supabase database
success = insert_matchups(client, season.id, roster_matchups, club_ids)

print(f"Insert matchups for week {week} succeeded." if success else f"Insert matchups for week {week} failed.")