# Help Panel - Admin Usage Guide

Welcome to the Help Panel Admin Guide. This document explains how to use the Help Panel Dashboard (`/helpadmin`) to manage content, create pages, and format text.

## 1. Accessing the Dashboard

To open the management interface, type the following command in-game:
**`/helpadmin`**

*Note: You must be logged in as an administrator (or have appropriate ACL rights) to use this command.*

---

## 2. Managing Categories

### Creating a Category
1. Click the **"Add"** button at the bottom left.
2. Enter the **Category Name** (e.g., "Server Rules").
3. **Restricting Access (Optional):**
   - Below the name, you will see a list of ACL Groups (e.g., Admin, Moderator).
   - Double-click a group to toggle it.
   - If selected (green [X]), **ONLY** members of that group can see the category.
   - If **NO groups** are selected, the category is **Public** (visible to everyone).

### Editing a Category
1. Select a category from the list.
2. Click the **"Edit"** button.
3. You can rename the category or change which groups can see it.

### Reordering
- Use the **Up (▲)** and **Down (▼)** buttons to move the selected category higher or lower in the list.

---

## 3. Managing Pages

### Creating a Page
1. Select the Category where you want the page to appear.
2. Click **"New Page"**.
3. Enter a **Title** and the **Content**.
4. Click **"Save"**.

### Editing a Page
1. Select the page from the right-side list.
2. Click **"Edit Page"** (or double-click the page).
3. Modify the content and click **"Save"**.

### Reordering Pages
- Use the **Up (▲)** and **Down (▼)** buttons on the right side to change the order of pages.

---

## 4. Text Formatting (BBCode)

The Help Panel uses "BBCode" tags to style text. These tags are easy to use.

### Basic Styling
| Effect | Code | Example |
|:--- |:--- |:--- |
| **Bold** | `[b]Text[/b]` | [b]Important[/b] |
| *Italic* | `[i]Text[/i]` | [i]Emphasis[/i] |
| Size | `[size=1.5]Text[/size]` | [size=2.0]Big Title[/size] |
| Color | `[color=#FF0000]Text[/color]` | [color=#00FF00]Green Text[/color] |
| Font | `[font=default-bold]Text[/font]` | [font=bankgothic]Cool Font[/font] |

*Available Fonts:* `default`, `default-bold`, `clear`, `arial`, `sans`, `pricedown`, `bankgothic`, `diploma`, `beckett`.

### Alignment
- **Center:** `[center]Centered Text[/center]`
- **Right:** `[right]Right Aligned[/right]`

### Lists
**Bulleted List:**
```
[list]
- Item 1
- Item 2
[/list]
```
**Numbered List:**
```
[olist]
1. First Step
2. Second Step
[/olist]
```

### Images
You can use images from the internet (URL must end in .png, .jpg, etc).
```
[img]https://example.com/image.png[/img]
```
**Advanced Image (Size & Align):**
```
[img width=300 height=150 align=center]https://example.com/image.png[/img]
```
*Supported alignments:* `left` (default), `center`, `right`

### Tables
Tables are great for lists of commands or stats.
- `header=true`: Makes the first row a dark header.
- `border=true`: Adds lines around cells.
- `align=center`: Centers the table (also supports `left`, `right`).
- Rows start with `|`. Cells are separated by `|`.

**Example Table:**
```
[table header=true border=true align=center]
| Command | Description | Level |
| /help | Shows help | User |
| /admin | Opens panel | Admin |
[/table]
```

---

## 5. Tips & Tricks
- **Combine Tags:** You can make text bold AND colored: `[b][color=#FF0000]WARNING[/color][/b]`
- **Colors in Tables:** You can use color codes inside table cells: `| [color=#00FF00]Enabled[/color] |`
- **Scrolling:** The panel supports mouse wheel and also "click-and-drag" on the scrollbar.
