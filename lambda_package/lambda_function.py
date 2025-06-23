import httpx

import json

import random
 
# Public FastAPI EC2 URL

FASTAPI_URL = "http://54.163.37.68:8001/locations"
 
# Replace with your actual JWT

JWT_TOKEN = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
 
HEADERS = {

    "Authorization": JWT_TOKEN,

    "Content-Type": "application/json"

}
 
def generate_location(suffix=None):

    if not suffix:

        suffix = str(random.randint(1000, 9999))

    return {

        "country": f"Country{suffix}",

        "city_id": f"City{suffix}",

        "city_name": f"CityName{suffix}",

        "pincode": 100000 + int(suffix),

        "state_name": f"State{suffix}"

    }
 
def lambda_handler(event, context):

    try:

        with httpx.Client(timeout=10.0) as client:

            # --- Step 1: CREATE location 1 ---

            suffix1 = str(random.randint(1000, 9999))

            location1 = generate_location(suffix1)

            resp_create1 = client.post(FASTAPI_URL, json=location1, headers=HEADERS)

            resp_create1.raise_for_status()
 
            # --- Step 2: CREATE location 2 ---

            suffix2 = str(random.randint(1000, 9999))

            location2 = generate_location(suffix2)

            resp_create2 = client.post(FASTAPI_URL, json=location2, headers=HEADERS)

            resp_create2.raise_for_status()
 
            # --- Step 3: READ records after creation ---

            resp_read = client.get(FASTAPI_URL, params={"country": location1["country"]}, headers=HEADERS)

            resp_read.raise_for_status()
 
            # --- Step 4: UPDATE location 1 ---

            updated_location1 = location1.copy()

            updated_location1["city_name"] = "UpdatedCity"

            updated_location1["state_name"] = "UpdatedState"

            resp_update = client.put(

                f"{FASTAPI_URL}?country={location1['country']}&city_id={location1['city_id']}",

                json=updated_location1,

                headers=HEADERS

            )

            resp_update.raise_for_status()
 
            # --- Step 5: DELETE location 2 ---

            resp_delete = client.delete(

                FASTAPI_URL,

                params={"country": location2["country"], "city_id": location2["city_id"]},

                headers=HEADERS

            )

            resp_delete.raise_for_status()
 
            return {

                "statusCode": 200,

                "body": json.dumps({

                    "message": "CRUD operations completed: create x2 → read → update → delete",

                    "created": [location1, location2],

                    "read_result": resp_read.json(),

                    "updated": updated_location1,

                    "deleted": {"country": location2["country"], "city_id": location2["city_id"]},

                    "responses": {

                        "create1": resp_create1.json(),

                        "create2": resp_create2.json(),

                        "read": resp_read.json(),

                        "update": resp_update.json(),

                        "delete": resp_delete.json()

                    }

                }),

                "headers": {"Content-Type": "application/json"}

            }
 
    except httpx.HTTPStatusError as e:

        return {

            "statusCode": e.response.status_code,

            "body": json.dumps({"error": e.response.text}),

            "headers": {"Content-Type": "application/json"}

        }
 
    except Exception as e:

        return {

            "statusCode": 500,

            "body": json.dumps({"error": str(e)}),

            "headers": {"Content-Type": "application/json"}

        }

 