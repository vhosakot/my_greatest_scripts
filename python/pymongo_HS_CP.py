#! /usr/bin/python3

# Steps to run this script:
#   python3 -m venv myenv
#   source myenv/bin/activate
#   python3 -m pip install pymongo
#   ./myenv/bin/python3 pymongo_HS_CP.py
#   deactivate
#   rm -rf myenv

import json
from pymongo import MongoClient

def list_all_documents():
    # Connect to the MongoDB server
    client = MongoClient("mongodb+srv://<username>:<password>@<DNS.mongodb.net>")

    # Get the list of all databases
    databases = client.list_database_names()

    for db_name in databases:
        if db_name in ["admin", "config", "local"]:
            continue

        print(f"\nDatabase: {db_name}")
        database = client[db_name]

        # Get the list of all collections in the database
        collections = database.list_collection_names()
        for collection_name in collections:
            if collection_name in ["exclude-1", "exclude-2"]:
                continue

            print(f"  Collection: {collection_name}")
            collection = database[collection_name]

            # Retrieve and print all documents in the collection
            documents = collection.find()
            # for document in documents:
                # print(f"    Document: {json.dumps(document, indent=4, default=str)}")

# Execute the function
list_all_documents()
