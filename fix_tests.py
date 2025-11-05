import re
import glob

# Pattern to match AggregatedInventoryItem constructor calls
pattern = r'(AggregatedInventoryItem\s*\([^)]*?categoryName:\s*[\'"][^\'"]*[\'"],)'

def add_total_value(match):
    return match.group(1) + '\n        totalValue: 0.0,'

# Find all test files
test_files = [
    'test/features/inventory/presentation/widgets/simple_inventory_card_test.dart',
    'test/features/inventory/presentation/widgets/aggregated_inventory_card_test.dart',
    'test/features/inventory/presentation/screens/inventory_query_screen_test.dart',
    'test/features/inventory/presentation/providers/inventory_query_providers_test.dart',
]

for file_path in test_files:
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Add totalValue parameter
        modified_content = re.sub(pattern, add_total_value, content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(modified_content)
        
        print(f"Fixed: {file_path}")
    except Exception as e:
        print(f"Error fixing {file_path}: {e}")

print("Done!")
