import os
import json

def delete_data_file(file_name):
    file_path = file_name
    if os.path.exists(file_path):
        os.remove(file_path)

def read_config_file(file_path):
    with open(file_path, "r") as f:
        data = json.load(f)
    return data
