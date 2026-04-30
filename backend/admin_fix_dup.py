from pathlib import Path
path = Path('d:/2026/Rachita/rachita/backend/Rachita.Api/wwwroot/admin/index.html')
text = path.read_text(encoding='utf-8')
marker = '<div class="flex h-screen overflow-hidden">'
idx1 = text.find(marker)
idx2 = text.find(marker, idx1 + 1)
print('Removing duplicate app tree from', idx1, 'to', idx2)
new_text = text[:idx1] + text[idx2:]
path.write_text(new_text, encoding='utf-8')
print('Removed successfully')
print('New file size:', len(new_text))
