import json

def get_user_input():
    all_apps_data = {}
    app_count = 0

    while True:
        app_count += 1
        app_name = f"app_{app_count}.0"

        print(f"Enter details for {app_name}:")
        milestone_count = int(input("Enter the number of milestones: ") or 1)
        app_data = {
            "appName": input("Enter web app name: "),
            "applianceName": input("Enter appliance name: "),
            "host": "telegraf.local",
            "userFlowName": input("Enter user flow name: "),
            "webAppId": input("Enter web app ID: "),
            "webPathId": input("Enter web path ID: "),
            "webUrlTarget": input("Enter Web App URL Target: "),
            "ispName": input("Enter ISP name (ispName): "),
            "pathId": input("Enter path ID: "),
            "pathUrlTarget": input("Enter path URL target: "),
            "networkType": input("Enter network type (default: WAN): ") or "WAN",
            "web_tag_category": input("Enter web tag category (default: null): ") or "null",
            "web_tag_value": input("Enter web tag value (default: null): ") or "null",
            "connectionType": input("Enter connection type (default: Wired): ") or "Wired",
            "path_tag_category": input("Enter path tag category (default: null): ") or "null",
            "path_tag_value": input("Enter path tag value (default: null): ") or "null",
            "vpn": input("Enter VPN status (default: Inactive): ") or "Inactive",
        }

        milestones_data = {}

        for i in range(1, milestone_count + 1):
            milestone_app_name = f"{app_name}.{i - 1}"
            milestoneName = input(f"Enter milestone {i} name (milestoneName): ")
            milestone = f"{i - 1}"

            milestones_data[milestone_app_name] = {
                **app_data, "milestone": milestone, "milestoneName": milestoneName,
            }

        all_apps_data.update(milestones_data)

        add_another_app = input("Do you want to add another app? (yes/no): ")
        if add_another_app.lower() != "yes":
            break

    return all_apps_data

def main():
    config_existing_tests = get_user_input()

    # Output the dictionary to a new file named "config_demo_tests.json"
    with open("config_existing_tests.json", "w") as f:
        json.dump(config_existing_tests, f, indent=4)

if __name__ == "__main__":
    main()
