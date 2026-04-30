from pathlib import Path
path = Path('d:/2026/Rachita/rachita/backend/Rachita.Api/wwwroot/admin/index.html')
text = path.read_text(encoding='utf-8')
marker = '<div class="flex h-screen overflow-hidden">'
idx1 = text.find(marker)
idx2 = text.find(marker, idx1 + 1)
print('idx1', idx1, 'idx2', idx2)
print('count', text.count(marker))
for i, idx in enumerate([i for i in range(len(text)) if text.startswith(marker, i)]):
    print(i, idx)
