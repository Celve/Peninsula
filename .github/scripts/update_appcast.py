#!/usr/bin/env python3
import os
import re
import xml.etree.ElementTree as ET
from datetime import datetime
import xml.dom.minidom as minidom

def parse_version_tag(tag):
    """
    Parse version tag like 'v0.0.11.post0' or 'v1.2.3'
    Returns tuple: (short_version, full_version)
    """
    # Remove 'v' prefix if present
    version = tag.lstrip('v')
    
    # Extract short version (major.minor) and full version
    parts = version.split('.')
    if len(parts) >= 2:
        short_version = f"{parts[0]}.{parts[1]}"
    else:
        short_version = version
    
    return short_version, version

def format_date(iso_date):
    """
    Convert ISO date to RSS pubDate format
    Example: 'Sun, 01 Jun 2025 14:53:15 +0800'
    """
    dt = datetime.fromisoformat(iso_date.replace('Z', '+00:00'))
    return dt.strftime('%a, %d %b %Y %H:%M:%S %z')

def update_appcast():
    # Get environment variables
    release_tag = os.environ.get('RELEASE_TAG', '')
    release_date = os.environ.get('RELEASE_DATE', '')
    
    if not release_tag:
        print("Error: RELEASE_TAG not set")
        return 1
    
    # Parse version information
    short_version, full_version = parse_version_tag(release_tag)
    
    # Format the publication date
    pub_date = format_date(release_date) if release_date else datetime.now().strftime('%a, %d %b %Y %H:%M:%S %z')
    
    # Construct download URL
    # Assuming the release asset is named Peninsula.zip
    download_url = f"https://github.com/Celve/Peninsula/releases/download/{release_tag}/Peninsula.zip"
    
    # Parse existing appcast.xml
    appcast_path = 'appcast.xml'
    
    # Register namespaces
    ET.register_namespace('sparkle', 'http://www.andymatuschak.org/xml-namespaces/sparkle')
    
    # Parse the XML file
    tree = ET.parse(appcast_path)
    root = tree.getroot()
    
    # Find the channel element
    channel = root.find('channel')
    if channel is None:
        print("Error: No channel element found in appcast.xml")
        return 1
    
    # Create new item element
    new_item = ET.Element('item')
    
    # Add title
    title = ET.SubElement(new_item, 'title')
    title.text = short_version
    
    # Add pubDate
    pub_date_elem = ET.SubElement(new_item, 'pubDate')
    pub_date_elem.text = pub_date
    
    # Add sparkle:version
    sparkle_version = ET.SubElement(new_item, '{http://www.andymatuschak.org/xml-namespaces/sparkle}version')
    sparkle_version.text = full_version
    
    # Add sparkle:shortVersionString
    sparkle_short_version = ET.SubElement(new_item, '{http://www.andymatuschak.org/xml-namespaces/sparkle}shortVersionString')
    sparkle_short_version.text = short_version
    
    # Add sparkle:minimumSystemVersion
    sparkle_min_sys = ET.SubElement(new_item, '{http://www.andymatuschak.org/xml-namespaces/sparkle}minimumSystemVersion')
    sparkle_min_sys.text = '14.0'
    
    # Add enclosure
    enclosure = ET.SubElement(new_item, 'enclosure')
    enclosure.set('url', download_url)
    enclosure.set('type', 'application/octet-stream')
    
    # Find existing items and insert new item at the beginning
    existing_items = channel.findall('item')
    
    # Remove all existing items
    for item in existing_items:
        channel.remove(item)
    
    # Insert new item first
    insert_index = 0
    for i, child in enumerate(channel):
        if child.tag != 'title':
            insert_index = i
            break
    channel.insert(insert_index + 1, new_item)
    
    # Re-add existing items (keep history)
    for item in existing_items[:4]:  # Keep only last 4 versions
        channel.append(item)
    
    # Format the XML with proper indentation
    xml_str = ET.tostring(root, encoding='unicode')
    dom = minidom.parseString(xml_str)
    
    # Get pretty printed XML and remove empty lines
    pretty_xml = dom.toprettyxml(indent='    ')
    # Remove empty lines and excessive whitespace
    lines = [line for line in pretty_xml.split('\n') if line.strip()]
    
    # Write formatted XML
    with open(appcast_path, 'w') as f:
        f.write('\n'.join(lines))
    
    print(f"Successfully updated appcast.xml for version {full_version}")
    return 0

if __name__ == '__main__':
    exit(update_appcast())