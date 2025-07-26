#!/usr/bin/env python3
"""
Script to generate config.h from .env file for ESP32 project
Run this script whenever you update the .env file
"""

import os
import re

def parse_env_file(env_path):
    """Parse .env file and return a dictionary of key-value pairs"""
    config = {}
    
    if not os.path.exists(env_path):
        print(f"Error: {env_path} not found")
        return None
    
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip comments and empty lines
            if line.startswith('#') or not line:
                continue
            
            if '=' in line:
                key, value = line.split('=', 1)
                config[key.strip()] = value.strip()
    
    return config

def parse_mac_address(mac_str):
    """Convert MAC address string to C array format"""
    # Remove colons and convert to uppercase
    mac_clean = mac_str.replace(':', '').upper()
    
    if len(mac_clean) != 12:
        raise ValueError(f"Invalid MAC address: {mac_str}")
    
    # Convert to byte array format
    bytes_list = []
    for i in range(0, 12, 2):
        hex_byte = mac_clean[i:i+2]
        bytes_list.append(f"0x{hex_byte}")
    
    return "{ " + ", ".join(bytes_list) + " }"

def generate_config_h(config, output_path):
    """Generate config.h file from configuration dictionary"""
    
    header_content = """#ifndef CONFIG_H
#define CONFIG_H

// This file is auto-generated from .env
// Modify the .env file instead of editing this directly

"""
    
    # WiFi Configuration
    if 'WIFI_SSID' in config and 'WIFI_PASSWORD' in config:
        header_content += "// WiFi Configuration\n"
        header_content += f'#define WIFI_SSID "{config["WIFI_SSID"]}"\n'
        header_content += f'#define WIFI_PASSWORD "{config["WIFI_PASSWORD"]}"\n\n'
    
    # Telegram Configuration
    if 'BOT_TOKEN' in config and 'CHAT_ID' in config:
        header_content += "// Telegram Bot Configuration\n"
        header_content += f'#define BOT_TOKEN "{config["BOT_TOKEN"]}"\n'
        header_content += f'#define CHAT_ID "{config["CHAT_ID"]}"\n\n'
    
    # MAC Address
    if 'MAC_ADDRESS' in config:
        try:
            mac_array = parse_mac_address(config['MAC_ADDRESS'])
            header_content += "// Target PC MAC Address\n"
            header_content += f"#define MAC_ADDRESS {mac_array}\n\n"
        except ValueError as e:
            print(f"Warning: {e}")
    
    header_content += "#endif\n"
    
    # Write to file
    with open(output_path, 'w') as f:
        f.write(header_content)
    
    print(f"Generated {output_path} successfully!")

def main():
    # Paths
    env_path = '.env'
    config_h_path = 'WOL_ESP32/config.h'
    
    # Parse .env file
    config = parse_env_file(env_path)
    if config is None:
        return
    
    print("Found configuration:")
    for key, value in config.items():
        if 'PASSWORD' in key or 'TOKEN' in key:
            print(f"  {key} = {'*' * len(value)}")
        else:
            print(f"  {key} = {value}")
    
    # Generate config.h
    generate_config_h(config, config_h_path)

if __name__ == "__main__":
    main()
