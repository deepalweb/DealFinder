import re

with open(r'c:\Users\DeepalRupasinghe\DealFinder-1\mobile_app\lib\src\screens\deal_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and remove the "Sold by" duplicate merchant section
pattern = r"          if \(statusChips\.isNotEmpty\) \.\.\.\[\r?\n            Wrap\(\r?\n              spacing: 8,\r?\n              runSpacing: 8,\r?\n              children: statusChips,\r?\n            \),\r?\n            const SizedBox\(height: 18\),\r?\n          \],\r?\n          if \(hasMerchant && merchantName != null\) \.\.\.\[\r?\n.*?          \],\r?\n          if \(hasPriceInfo"

replacement = r"""          if (countdownText != null || distanceLabel.isNotEmpty)
            const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (statusChips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusChips,
            ),
          ],
          if (hasPriceInfo"""

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open(r'c:\Users\DeepalRupasinghe\DealFinder-1\mobile_app\lib\src\screens\deal_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed duplicate merchant section")
