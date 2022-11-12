import psycopg2
import yaml

old_creds = {
    "dbname": "postgres",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5433,
}

new_creds = {
    "dbname": "bandejao-bot",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5432,
}

old_conn = psycopg2.connect(**old_creds)
old_cur = old_conn.cursor()

new_conn = psycopg2.connect(**new_creds)
new_cur = new_conn.cursor()

restaurants = dict()
campi = dict()

restaurant_maps = {
    ':piracicaba': '1',
    ':restaurante_area1': '2',
    ':restaurante_area2': '3',
    ':restaurante_crhea': '4',
    ':pirassununga': '5',
    ':central': '6',
    ':pusp_c': '7',
    ':fisica': '8',
    ':quimicas': '9',
    ':fac_saude_publica': '11',
    ':escola_de_enfermagem': '12',
    ':each': '13',
    ':fac_direito': '14',
    ':eel_area_i': '17',
    ':restaurante_central': '19',
    ':bauru': '20',
    ':eel_area_ii': '23',
}

configurations = [
    '{"period":"Lunch","weekday":"thu"}',
    '{"period":"Dinner","weekday":"fri"}',
    '{"period":"Dinner","weekday":"sat"}',
    '{"period":"Dinner","weekday":"wed"}',
    '{"period":"Lunch","weekday":"tue"}',
    '{"period":"Lunch","weekday":"sun"}',
    '{"period":"Lunch","weekday":"sat"}',
    '{"period":"Lunch","weekday":"wed"}',
    '{"period":"Dinner","weekday":"thu"}',
    '{"period":"Lunch","weekday":"fri"}',
    '{"period":"Dinner","weekday":"mon"}',
    '{"period":"Dinner","weekday":"tue"}',
    '{"period":"Dinner","weekday":"sun"}',
    '{"period":"Lunch","weekday":"mon"}',
]

old_cur.execute("SELECT * from users;")
for user in old_cur.fetchall():
    user_id = user[0]
    username = user[1]
    first_name = user[2]
    last_name = user[3]
    created_at = user[4]
    updated_at = user[5]

    new_cur.execute("INSERT INTO users VALUES (%s, %s, %s, %s, %s, %s)",
                    (user_id, username, first_name, last_name, created_at, updated_at))

    prefs = yaml.safe_load(user[7])
    for pref in prefs:
        new_cur.execute("INSERT INTO configurations VALUES (%s, %s) ON CONFLICT DO NOTHING",
                        (user_id, restaurant_maps[pref[":restaurant"]]))
        if pref[":restaurant"] in restaurants:
            restaurants[pref[":restaurant"]
                        ] = restaurants[pref[":restaurant"]] + 1
        else:
            restaurants[pref[":restaurant"]] = 1
        if pref[":campus"] in campi:
            campi[pref[":campus"]] = campi[pref[":campus"]] + 1
        else:
            campi[pref[":campus"]] = 1

old_cur.execute("SELECT * from schedules;")
for schedule in old_cur.fetchall():
    user_id = schedule[1]
    chat_id = schedule[2]
    for config in configurations:
        new_cur.execute("INSERT INTO schedules VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
                        (chat_id, user_id, config))

new_cur.execute("COMMIT")

print(restaurants)
print(campi)
