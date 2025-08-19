import requests
import base64
import yaml
import argparse

def fetch_subscription(url):
    """
    Fetches and decodes a clash subscription.
    (Currently not used in the main logic, but kept for future use)
    """
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for bad status codes

        # Try to decode from base64, if it fails, assume plain text
        try:
            # Add padding if necessary
            missing_padding = len(response.content) % 4
            if missing_padding != 0:
                response.content += b'='* (4 - missing_padding)
            decoded_content = base64.b64decode(response.content).decode('utf-8')
        except Exception:
            decoded_content = response.text

        proxies = decoded_content.strip().split('\n')
        return [proxy for proxy in proxies if proxy] # Filter out empty lines
    except requests.exceptions.RequestException as e:
        print(f"Error fetching subscription from {url}: {e}")
        return None

def load_config(path):
    """
    Loads a YAML configuration file.
    """
    try:
        with open(path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
            return config
    except FileNotFoundError:
        print(f"Error: Configuration file not found at {path}")
        return None
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file at {path}: {e}")
        return None

def generate_config(base_config, sub_url, output_path):
    """
    Generates the final config by injecting the subscription url into the 'all' provider.
    """
    if 'proxy-providers' not in base_config or 'all' not in base_config['proxy-providers']:
        print("Error: 'proxy-providers' section or provider 'all' not found in the base config.")
        return

    # Update the subscription URL
    base_config['proxy-providers']['all']['url'] = sub_url

    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            # Use sort_keys=False to preserve the order of keys in the original file
            # Use allow_unicode=True to support non-ASCII characters in the output
            yaml.dump(base_config, f, sort_keys=False, allow_unicode=True)
        print(f"Successfully generated config file at {output_path}")
    except Exception as e:
        print(f"Error writing config file: {e}")

def main():
    """
    Main function to parse arguments and run the converter.
    """
    parser = argparse.ArgumentParser(description="A simple Clash subscription converter for smart groups.")
    parser.add_argument('-i', '--input', default='smart-rule.yaml',
                        help='Path to the base configuration file (default: smart-rule.yaml)')
    parser.add_argument('-o', '--output', default='config.yaml',
                        help='Path to the output configuration file (default: config.yaml)')
    parser.add_argument('-s', '--sub', required=True,
                        help='The subscription URL')

    args = parser.parse_args()

    # --- Load Base Config ---
    print(f"Loading base configuration from {args.input}...")
    base_config = load_config(args.input)

    if base_config:
        print("Base configuration loaded successfully.")

        # --- Generate Final Config ---
        print(f"Generating final config with subscription URL: {args.sub}")
        generate_config(base_config, args.sub, args.output)
    else:
        print("Failed to load base configuration. Aborting.")


if __name__ == '__main__':
    main()
