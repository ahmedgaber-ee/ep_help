# EP Help System - Complete Syntax Guide
## Table of Contents
1. [Text Formatting](#text-formatting)
2. [Fonts](#fonts)
3. [Inline Decorations](#inline-decorations)
4. [Alignment](#alignment)
5. [Lists](#lists)
6. [Tables](#tables)
7. [Images](#images)
8. [Layout Containers](#layout-containers)
9. [Visual Separators](#visual-separators)
10. [Progress Bars](#progress-bars)
11. [Spacing](#spacing)
---
## Text Formatting
### Basic Styling
**Bold Text**
```
[b]This text is bold[/b]
```
**Italic Text**
```
[i]This text is italic[/i]
```
**Bold + Italic**
```
[b][i]This text is bold and italic[/i][/b]
```
### Colors
**Syntax:** `[color=HEXCODE]text[/color]`
```
[color=#FF0000]Red text[/color]
[color=#00FF00]Green text[/color]
[color=#0000FF]Blue text[/color]
[color=#FFD700]Golden text[/color]
```
**Note:** Colors can be 3-digit (#F00) or 6-digit (#FF0000) hex codes.
### Sizes
**Syntax:** `[size=NUMBER]text[/size]`
```
[size=0.8]Small text (80%)[/size]
Normal text (100%)
[size=1.2]Large text (120%)[/size]
[size=1.5]Larger text (150%)[/size]
[size=2.0]Huge text (200%)[/size]
```
**Note:** Size is a multiplier. 1.0 = normal, 2.0 = double size, 0.5 = half size.
---
## Fonts
### Available Fonts
**Roboto Family**
- `roboto-regular` - Standard body text
- `roboto-medium` - Medium weight
- `roboto-bold` - Bold weight
- `roboto-black` - Heaviest weight
**Gotham Family**
- `gotham-bold` - Modern bold
- `gotham-black` - Heaviest modern font
**Special Fonts**
- `digital` - Digital display font (great for numbers/stats)
### Font Syntax
**Basic:**
```
[font=FONTNAME]Your text here[/font]
```
**With Size:**
```
[font=FONTNAME size=NUMBER]Your text here[/font]
```
### Examples
```
[font=roboto-regular]Standard paragraph text[/font]
[font=roboto-bold size=14]Bold heading[/font]
[font=gotham-black size=24]Major Title[/font]
[font=digital size=18]12345[/font]
```
**Combining with other tags:**
```
[font=gotham-bold size=16][color=#FF6B35]Colored Bold Title[/color][/font]
```
---
## Inline Decorations
### Highlights (Mark)
**Syntax:** `[mark=HEXCOLOR]text[/mark]`
```
This is [mark=#FFFF00]highlighted in yellow[/mark].
Warning: [mark=#FF4444]Danger zone[/mark]!
Success: [mark=#44FF44]Operation complete[/mark].
```
### Keyboard Keys
**Syntax:** `[key]keyname[/key]`
```
Press [key]Enter[/key] to confirm.
Use [key]W[/key] [key]A[/key] [key]S[/key] [key]D[/key] to move.
Hold [key]Shift[/key] and press [key]Space[/key].
```
**Examples with instructions:**
```
To open the menu, press [key]M[/key].
Save your progress with [key]Ctrl[/key] + [key]S[/key].
```
---
## Alignment
### Center Alignment
```
[center]This text is centered[/center]
```
### Right Alignment
```
[right]This text is right-aligned[/right]
```
### Left Alignment (Default)
```
This text is left-aligned by default.
```
**Note:** Alignment applies to the entire paragraph/block.
---
## Lists
### Unordered Lists (Bullets)
```
[list]
- First item
- Second item
- Third item
[/list]
```
**With formatting:**
```
[list]
- [b]Bold item[/b]
- Item with [color=#FF0000]red text[/color]
- Item with [key]keybind[/key]
- Item with [mark=#FFFF00]highlight[/mark]
[/list]
```
### Ordered Lists (Numbered)
```
[olist]
1. First step
2. Second step
3. Third step
[/olist]
```
**Instructions example:**
```
[olist]
1. Press [key]F1[/key] to open the menu
2. Select your character class
3. Click [mark=#44FF44]Confirm[/mark]
4. Start playing!
[/olist]
```
---
## Tables
### Basic Table
```
[table header=true border=true]
| Column 1 | Column 2 | Column 3
| Row 1 Data | Data | Data
| Row 2 Data | Data | Data
[/table]
```
### Table Attributes
**Required:**
- `header=true` - First row is header
- `header=false` - No header row
**Optional:**
- `border=true` - Draw borders
- `border=false` - No borders
- `align=left|center|right` - Table position
- `header_align=left|center|right` - Header text alignment
- `content_align=left|center|right` - Body text alignment
### Table Examples
**Example 1: Player Statistics**
```
[table header=true border=true align=center header_align=center content_align=left]
| Player | Score | Status
| John | 1500 | Online
| Sarah | 1200 | Offline
| Mike | 950 | Online
[/table]
```
**Example 2: Financial Data (Right-Aligned)**
```
[table header=true border=true align=center header_align=right content_align=right]
| Description | Debit | Credit | Balance
| Initial Deposit | - | $1,000.00 | $1,000.00
| Purchase | $50.00 | - | $950.00
[/table]
```
**Example 3: Mixed Alignment**
```
[table header=true border=true align=center header_align=center content_align=left]
| ID | Name | Value
| 001 | Item One | 100
| 002 | Item Two | 200
[/table]
```
**With Colors and Formatting:**
```
[table header=true border=true]
| Rank | Player | Points
| [color=#FFD700]#1[/color] | [b]TopPlayer[/b] | [font=digital]24,500[/font]
| [color=#C0C0C0]#2[/color] | [b]Runner Up[/b] | [font=digital]18,200[/font]
[/table]
```
---
## Images
### Basic Image
```
[img]path/to/image.png[/img]
```
### Image with Attributes
**Syntax:**
```
[img width=NUMBER height=NUMBER align=left|center|right]path/to/image.png[/img]
```
**Examples:**
```
[img width=300 height=200]assets/images/banner.png[/img]
[img width=400 align=center]assets/images/logo.png[/img]
```
**Remote Images:**
```
[img width=500]https://example.com/image.png[/img]
```
---
## Layout Containers
### Boxes
**Syntax:**
```
[box color=HEX padding=NUMBER radius=NUMBER border=HEX]
Content here
[/box]
```
**Attributes:**
- `color` - Background color (hex)
- `padding` - Internal spacing in pixels (default: 15)
- `radius` - Corner roundness in pixels (default: 10)
- `border` - Border color (hex, optional)
**Examples:**
**Simple Box:**
```
[box color=#222233 padding=15]
This is a simple box with dark background.
[/box]
```
**Styled Box:**
```
[box color=#2a2a35 padding=20 radius=12 border=#4ECDC4]
[font=gotham-bold][color=#4ECDC4]Alert Box[/color][/font]
[gap size=5]
This is an alert box with border and custom styling.
[/box]
```
**Nested Boxes:**
```
[box color=#1a1a26 padding=20]
Outer Box
[gap size=10]
[box color=#2a2a35 padding=15 radius=8]
Inner Box
[/box]
[/box]
```
### Grid Layouts (Rows & Columns)
**Basic Structure:**
```
[row]
[col width=50%]
Left column content
[/col]
[col width=50%]
Right column content
[/col]
[/row]
```
**Width Options:**
- Percentage: `width=50%` (takes 50% of available width)
- Pixels: `width=300` (fixed 300px width)
- Auto: `width=1` or omit (distributes remaining space)
**Two Column Example:**
```
[row]
[col width=50%]
[box color=#222233 padding=15]
Left side content
[/box]
[/col]
[col width=50%]
[box color=#222233 padding=15]
Right side content
[/box]
[/col]
[/row]
```
**Three Column Example:**
```
[row]
[col width=33%]
Column 1
[/col]
[col width=33%]
Column 2
[/col]
[col width=33%]
Column 3
[/col]
[/row]
```
**Asymmetric Layout (70/30):**
```
[row]
[col width=70%]
Main content area
[/col]
[col width=30%]
Sidebar
[/col]
[/row]
```
**Complex Example:**
```
[row]
[col width=60%]
[box color=#1a2a1a padding=15]
[font=gotham-bold]Main Article[/font]
[gap size=10]
Lorem ipsum dolor sit amet...
[/box]
[/col]
[col width=40%]
[box color=#2a1a1a padding=15]
[font=gotham-bold]Quick Stats[/font]
[gap size=10]
[progress value=75 max=100 color=#44FF44 label="Health"]
[/box]
[/col]
[/row]
```
---
## Visual Separators
### Logo Separator
**Basic:**
```
[separator]
```
**Colored:**
```
[separator color=#FF6B35]
```
**Examples:**
```
[separator]
[separator color=#4ECDC4]
[separator color=#FFD700]
```
### Custom Lines
**Syntax:**
```
[line width=WIDTH height=THICKNESS color=HEX centered=true|false]
```
**Attributes:**
- `width` - "100%" or "50%" or pixel number (default: 100%)
- `height` - Thickness in pixels (default: 2)
- `color` - Line color (hex)
- `centered` - Center the line (true/false)
**Examples:**
**Thin line (default):**
```
[line]
```
**Thick colored line:**
```
[line height=4 color=#FF6B35]
```
**Centered half-width line:**
```
[line width=50% centered=true color=#4ECDC4]
```
**Extra thick accent line:**
```
[line height=10 color=#FFD700]
```
**Different widths:**
```
[line width=25% color=#FF4444]
[line width=50% color=#FFAA00]
[line width=75% color=#44FF44]
[line width=100% color=#4444FF]
```
---
## Progress Bars
**Syntax:**
```
[progress value=NUMBER max=NUMBER color=HEX label="TEXT"]
```
**Attributes:**
- `value` - Current value (required)
- `max` - Maximum value (default: 100)
- `color` - Bar color (hex, optional)
- `label` - Text label (optional)
**Examples:**
**Basic:**
```
[progress value=75 max=100]
```
**With Label:**
```
[progress value=85 max=100 color=#44FF44 label="Health"]
```
**Skill Progress:**
```
[font=roboto-bold]Driving Skill[/font]
[progress value=92 max=100 color=#00AAFF label="Master"]
```
**Multiple Stats:**
```
[progress value=85 max=100 color=#44FF44 label="HP"]
[gap size=5]
[progress value=60 max=100 color=#4444FF label="Armor"]
[gap size=5]
[progress value=40 max=100 color=#FFAA00 label="Stamina"]
```
---
## Spacing
### Gaps
**Syntax:**
```
[gap size=NUMBER]
```
**Examples:**
```
First paragraph.
[gap size=10]
Small gap above (10px).
[gap size=20]
Medium gap above (20px).
[gap size=40]
Large gap above (40px).
```
**Common Uses:**
```
[font=gotham-bold size=18]Section Title[/font]
[gap size=10]
Section content starts here...
[gap size=20]
[font=gotham-bold size=18]Next Section[/font]
```
---
## Complete Examples
### Example 1: Alert Box with All Features
```
[box color=#2a1a26 padding=20 radius=12 border=#FF6B35]
[font=gotham-bold size=16][color=#FF6B35]⚠ Important Notice[/color][/font]
[gap size=10]
[font=roboto-regular]To complete this action, you must:[/font]
[gap size=5]
[olist]
1. Press [key]Esc[/key] to open the menu
2. Navigate to [mark=#4ECDC4]Settings[/mark]
3. Enable [b]Advanced Mode[/b]
4. Click [mark=#44FF44]Save[/mark]
[/olist]
[gap size=10]
[progress value=60 max=100 color=#FFAA00 label="Progress"]
[/box]
```
### Example 2: Stats Panel
```
[row]
[col width=50%]
[box color=#1a1a26 padding=15 border=#44FF44]
[center][font=gotham-bold][color=#44FF44]Player Stats[/color][/font][/center]
[gap size=10]
[font=roboto-bold]Health[/font]
[progress value=85 max=100 color=#44FF44 label="HP"]
[gap size=5]
[font=roboto-bold]Armor[/font]
[progress value=60 max=100 color=#4444FF label="Armor"]
[gap size=5]
[font=roboto-bold]Stamina[/font]
[progress value=40 max=100 color=#FFAA00 label="Stamina"]
[/box]
[/col]
[col width=50%]
[box color=#1a2a1a padding=15 border=#FFD700]
[center][font=gotham-bold][color=#FFD700]Skills[/color][/font][/center]
[gap size=10]
[font=roboto-bold]Driving[/font]
[progress value=92 max=100 color=#00AAFF label="Master"]
[gap size=5]
[font=roboto-bold]Shooting[/font]
[progress value=75 max=100 color=#FF6B35 label="Advanced"]
[gap size=5]
[font=roboto-bold]Flying[/font]
[progress value=45 max=100 color=#9B59B6 label="Intermediate"]
[/box]
[/col]
[/row]
```
### Example 3: Data Table with Instructions
```
[font=gotham-bold size=18]Server List[/font]
[line]
[gap size=10]
[table header=true border=true align=center header_align=center content_align=left]
| Server | Location | Players | Ping | Action
| [b]US-EAST-01[/b] | New York | 48/64 | [color=#00FF00]12ms[/color] | [key]Join[/key]
| [b]US-WEST-01[/b] | California | 52/64 | [color=#00FF00]18ms[/color] | [key]Join[/key]
| [b]EU-CENTRAL[/b] | Frankfurt | 61/64 | [color=#FFAA00]45ms[/color] | [key]Join[/key]
| [b]ASIA-SE-01[/b] | Singapore | 38/64 | [color=#FF4444]120ms[/color] | [key]Join[/key]
[/table]
[gap size=10]
[box color=#222233 padding=15]
[font=roboto-bold]How to Join:[/font]
[gap size=5]
Click the [key]Join[/key] button or press [key]F5[/key] to refresh the list.
[/box]
```
---
## Best Practices
### 1. Color Consistency
Use a consistent color palette throughout your pages:
- Primary: `#FF6B35`
- Secondary: `#4ECDC4`
- Success: `#44FF44`
- Warning: `#FFAA00`
- Danger: `#FF4444`
- Info: `#4444FF`
### 2. Typography Hierarchy
- Titles: `[font=gotham-black size=28]`
- Headers: `[font=gotham-bold size=18]`
- Subheaders: `[font=roboto-bold size=14]`
- Body: `[font=roboto-regular size=12]`
### 3. Spacing
- Always use `[gap]` between major sections
- Use `[line]` to separate content visually
- Don't overuse separators
### 4. Boxes
- Use boxes to group related content
- Add borders to important boxes
- Use padding for readability (15-20px recommended)
### 5. Tables
- Always use `header=true` for data tables
- Use `border=true` for data, `border=false` for layouts
- Align numbers to the right, text to the left
### 6. Progress Bars
- Always include a label
- Use appropriate colors (green for health, blue for armor, etc.)
- Keep max value at 100 for percentages
---
## Common Mistakes to Avoid
❌ **Don't forget closing tags:**
```
[b]This is bold (WRONG - no closing tag)
[b]This is bold[/b] (CORRECT)
```
❌ **Don't nest the same tag:**
```
[b][b]Double bold[/b][/b] (WRONG)
[b]Bold text[/b] (CORRECT)
```
❌ **Don't use invalid hex colors:**
```
[color=red]Text[/color] (WRONG - use hex)
[color=#FF0000]Text[/color] (CORRECT)
```
❌ **Don't forget column widths add up:**
```
[row]
[col width=60%]...[/col]
[col width=60%]...[/col]  (WRONG - 120% total)
[/row]
[row]
[col width=60%]...[/col]
[col width=40%]...[/col]  (CORRECT - 100% total)
[/row]
```
---
## Quick Reference
| Feature | Tag |
|---------|-----|
| Bold | `[b]text[/b]` |
| Italic | `[i]text[/i]` |
| Color | `[color=#HEX]text[/color]` |
| Size | `[size=NUMBER]text[/size]` |
| Font | `[font=NAME size=NUMBER]text[/font]` |
| Highlight | `[mark=#HEX]text[/mark]` |
| Key | `[key]text[/key]` |
| Center | `[center]text[/center]` |
| Right | `[right]text[/right]` |
| List | `[list]- item[/list]` |
| Ordered List | `[olist]1. item[/olist]` |
| Table | `[table]...[/table]` |
| Image | `[img]path[/img]` |
| Box | `[box]...[/box]` |
| Row | `[row]...[/row]` |
| Column | `[col]...[/col]` |
| Separator | `[separator]` |
| Line | `[line]` |
| Progress | `[progress value=X max=Y]` |
| Gap | `[gap size=X]` |
