## ⚡ Quick Start
### For Players
1. Press **H** to open the help panel
2. Navigate categories using the sidebar
3. Scroll through content
4. Press **F1** again or **ESC** to close
### For Admins
1. Use `/helpadmin` to enable edit mode
2. Create/edit categories and pages
3. Use the built-in BBCode editor
4. Changes save automatically
## 📖 Usage Guide
### Basic Workflow
1. **Open** the help panel (F1)
2. **Browse** categories in the left sidebar
3. **Read** the content in the main area
4. **Search** for specific topics (Ctrl+F in browser)
5. **Close** when finished
### Creating Your First Page
The help system uses a simple BBCode-like syntax. Here's a basic example:
```
[center][font=gotham-bold size=24]My First Page[/font][/center]
[separator]
[font=gotham-bold size=16]Introduction[/font]
[line]
Welcome to my help page! Here's what you can do:
[list]
- Learn the basics
- Master advanced techniques
- Access helpful commands
[/list]
[gap size=20]
[box color=#222233 padding=15]
Press [key]F1[/key] to access this panel anytime!
[/box]
```
### Understanding the Structure
The help system has three levels:
1. **Categories** - Main sections (e.g., "Welcome", "Commands", "Rules")
2. **Pages** - Individual help topics within categories
3. **Content** - The actual text and formatting using BBCode
## ✨ Creating Content
### Step-by-Step Guide for Beginners
#### 1. Start with Plain Text
Just type your content normally:
```
This is a simple paragraph.
This is another paragraph.
```
#### 2. Add Basic Formatting
Make text **bold** or *italic*:
```
This is [b]bold text[/b].
This is [i]italic text[/i].
```
#### 3. Add Colors
Use hex color codes:
```
This is [color=#FF0000]red text[/color].
This is [color=#00FF00]green text[/color].
```
#### 4. Create Headings
Use fonts and sizes for headings:
```
[font=gotham-bold size=20]Main Heading[/font]
[font=roboto-bold size=14]Subheading[/font]
```
#### 5. Add Visual Elements
**Separator:**
```
[separator]
```
**Line:**
```
[line]
```
**Gap (spacing):**
```
[gap size=20]
```
#### 6. Create Lists
**Simple list:**
```
[list]
- First item
- Second item
- Third item
[/list]
```
**Numbered list:**
```
[olist]
1. First step
2. Second step
3. Third step
[/olist]
```
#### 7. Add Boxes for Important Info
```
[box color=#2a2a35 padding=15]
This is important information in a box!
[/box]
```
#### 8. Show Keyboard Keys
```
Press [key]Enter[/key] to continue.
Use [key]W[/key] [key]A[/key] [key]S[/key] [key]D[/key] to move.
```
#### 9. Highlight Text
```
This is [mark=#FFFF00]highlighted[/mark] text.
Warning: [mark=#FF4444]Do not do this![/mark]
```
#### 10. Create Tables
```
[table header=true border=true]
| Name | Score | Status
| John | 100 | Active
| Jane | 95 | Active
| Bob | 80 | Inactive
[/table]
```
### Complete Example for Beginners
Here's a full page example that's easy to understand:
```
[center][font=gotham-bold size=24]Server Rules[/font][/center]
[center][font=roboto-regular size=10]Please read carefully[/font][/center]
[separator]
[gap size=15]
[font=gotham-bold size=16]Basic Rules[/font]
[line]
[gap size=10]
[olist]
1. [b]No cheating[/b] - This will result in a permanent ban
2. [b]Respect others[/b] - Be kind to all players
3. [b]No spam[/b] - Don't flood the chat
4. [b]Follow staff instructions[/b] - Listen to admins
[/olist]
[gap size=20]
[box color=#2a1a26 padding=20 border=#FF4444]
[font=gotham-bold][color=#FF4444]⚠ Warning[/color][/font]
[gap size=5]
Breaking these rules will result in punishment!
[/box]
[gap size=20]
[font=gotham-bold size=16]How to Report[/font]
[line]
[gap size=10]
If you see someone breaking the rules:
[list]
- Press [key]F2[/key] to open the report menu
- Select the player's name
- Choose the [mark=#FFAA00]rule violation[/mark]
- Click [key]Submit[/key]
[/list]
[gap size=15]
[center][font=roboto-regular size=10]Thank you for keeping our server clean![/font][/center]
```
## 📝 Syntax Reference
### Text Formatting
| Feature | Syntax | Example |
|---------|--------|---------|
| Bold | `[b]text[/b]` | **Bold** |
| Italic | `[i]text[/i]` | *Italic* |
| Color | `[color=#HEX]text[/color]` | <span style="color:red">Colored</span> |
| Size | `[size=1.5]text[/size]` | Sized |
### Fonts
| Font | Usage | Best For |
|------|-------|----------|
| `roboto-regular` | Body text | Paragraphs, descriptions |
| `roboto-bold` | Emphasis | Subheadings, labels |
| `gotham-bold` | Headers | Section titles |
| `gotham-black` | Titles | Page titles |
| `digital` | Numbers | Stats, scores |
**Example:**
```
[font=gotham-bold size=18]Section Title[/font]
[font=roboto-regular size=12]Body text content[/font]
```
### Inline Decorations
**Highlights:**
```
[mark=#FFFF00]highlighted text[/mark]
```
**Keyboard Keys:**
```
[key]Enter[/key]
```
### Layout Elements
**Box:**
```
[box color=#222233 padding=15 radius=8 border=#4ECDC4]
Content
[/box]
```
**Columns:**
```
[row]
[col width=50%]Left content[/col]
[col width=50%]Right content[/col]
[/row]
```
**Separator:**
```
[separator]
[separator color=#FF6B35]
```
**Line:**
```
[line]
[line width=50% height=4 color=#4ECDC4 centered=true]
```
**Gap:**
```
[gap size=20]
```
### Data Elements
**Table:**
```
[table header=true border=true align=center]
| Column 1 | Column 2
| Data 1 | Data 2
[/table]
```
**Progress Bar:**
```
[progress value=75 max=100 color=#44FF44 label="Health"]
```
**Lists:**
```
[list]
- Item
[/list]
[olist]
1. Item
[/olist]
```
For complete syntax documentation, see [SYNTAX_GUIDE.md](SYNTAX_GUIDE.md).
## 💡 Examples
### Example 1: Welcome Message
```
[center][font=gotham-black size=28]Welcome to Our Server![/font][/center]
[separator]
[gap size=15]
[row]
[col width=50%]
[box color=#1a1a26 padding=15 border=#44FF44]
[center][font=gotham-bold][color=#44FF44]For New Players[/color][/font][/center]
[gap size=10]
Start your journey here! Press [key]F1[/key] for help.
[/box]
[/col]
[col width=50%]
[box color=#1a1a26 padding=15 border=#4444FF]
[center][font=gotham-bold][color=#4444FF]For Veterans[/color][/font][/center]
[gap size=10]
Check out the latest updates and features!
[/box]
[/col]
[/row]
```
### Example 2: Command Reference
```
[font=gotham-bold size=18]Essential Commands[/font]
[line]
[gap size=10]
[table header=true border=true align=center header_align=left content_align=left]
| Command | Description | Example
| [key]/help[/key] | Opens help panel | /help
| [key]/stats[/key] | View statistics | /stats
| [key]/pm[/key] | Private message | /pm John Hey!
[/table]
```
### Example 3: Statistics Display
```
[font=gotham-bold size=16]Your Progress[/font]
[line]
[gap size=10]
[font=roboto-bold]Level Progress[/font]
[font=digital size=18][color=#FFD700]LEVEL 42[/color][/font]
[progress value=75 max=100 color=#FFD700 label="XP"]
[gap size=10]
[font=roboto-bold]Skills[/font]
[progress value=92 max=100 color=#00AAFF label="Driving"]
[gap size=5]
[progress value=75 max=100 color=#FF6B35 label="Shooting"]
[gap size=5]
[progress value=45 max=100 color=#9B59B6 label="Flying"]
```
## ⚙️ Configuration
### ACL Setup
The system automatically creates permissions. Default groups with access:
- Console
- Leader
- Innovator
- Manager
To add more groups, edit `server/permissions.lua`:
```lua
local function hasAccess(player)
    local groups = {"Console", "Leader", "Innovator", "Manager", "YourGroup"}
    -- ...
end
```
### Color Palette
Default colors are defined in `client/player/renderer.lua`:
```lua
colors = {
    text = tocolor(230, 230, 230),
    textDim = tocolor(180, 180, 180),
    accent = tocolor(100, 180, 255),
    -- ...
}
```
### Font Sizes
Standard font sizes in `client/player/viewer.lua`:
```lua
fonts = {
    header = HelpViewer.getFont("roboto-bold", 20),
    sub = HelpViewer.getFont("roboto-medium", 14),
    body = HelpViewer.getFont("roboto", 10),
    -- ...
}
```
## 🎮 Commands
| Command | Permission | Description |
|---------|-----------|-------------|
| `/help` | All | Opens help panel |
| `/helpadmin` | Admin | Enables edit mode |
| `/helpreload` | Manager | Reloads help data |
## 🔧 API Documentation
### Client-Side Functions
**Toggle Help Panel:**
```lua
HelpViewer.toggle()
```
**Show Specific Page:**
```lua
HelpViewer.showPage(categoryID, pageID)
```
**Check if Panel is Open:**
```lua
local isOpen = HelpViewer.visible
```
### Server-Side Events
**Request Full Data:**
```lua
triggerServerEvent("helpPanel:requestFullData", localPlayer)
```
**Create Category:**
```lua
triggerServerEvent("helpPanel:createCategory", localPlayer, name, icon, order, allowedGroups)
```
**Create Page:**
```lua
triggerServerEvent("helpPanel:createPage", localPlayer, categoryID, title, content)
```
## 🐛 Troubleshooting
### Panel Won't Open
**Problem:** Pressing F1 does nothing
**Solutions:**
1. Check if resource is running: `status ep_help`
2. Restart the resource: `restart ep_help`
3. Check for Lua errors in server console
4. Verify F1 isn't bound to another resource
### Content Not Showing
**Problem:** Pages appear empty
**Solutions:**
1. Check `help_content.json` exists in `data/` folder
2. Verify JSON syntax (use JSON validator)
3. Check server console for parsing errors
4. Try `/helpreload` command
### Fonts Not Loading
**Problem:** Text appears in default font
**Solutions:**
1. Verify font files exist in `assets/fonts/`
2. Check `meta.xml` includes all font files
3. Restart the resource completely
4. Clear MTA cache and reconnect
### ACL Permissions
**Problem:** Players can't access certain categories
**Solutions:**
1. Check `allowedGroups` in category definition
2. Verify player's ACL group membership
3. Use empty string `""` for public access
4. Check permissions in `server/permissions.lua`
## 📚 Tips & Best Practices
### 1. Keep It Simple
Start with basic formatting and add complexity gradually:
```
✅ Good:
[font=gotham-bold]Title[/font]
Simple paragraph text.
❌ Over-complicated:
[font=gotham-bold size=18][color=#FF6B35][b][i]Title[/i][/b][/color][/font]
```
### 2. Use Consistent Colors
Define a color scheme and stick to it:
```
Primary: #FF6B35
Secondary: #4ECDC4
Success: #44FF44
Warning: #FFAA00
Danger: #FF4444
```
### 3. Group Related Content
Use boxes to group related information:
```
[box color=#222233 padding=15]
[font=gotham-bold]Related Info[/font]
Content here...
[/box]
```
### 4. Don't Overuse Formatting
Too much formatting is distracting:
```
✅ Good:
This is [b]important[/b] text.
❌ Bad:
[b][i][color=#FF0000][size=1.5]This[/size][/color][/i][/b] is [mark=#FFFF00][b]too[/b][/mark] [color=#00FF00]much[/color]!
```
### 5. Test Your Content
Always preview your pages before publishing:
1. Save the content
2. Reload the panel
3. Check for formatting issues
4. Test on different resolutions
## 🤝 Contributing
Contributions are welcome! Here's how:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
### Development Guidelines
- Follow existing code style
- Comment complex logic
- Test thoroughly before PR
- Update documentation
- Follow the golden rule: destroy all resources on panel close
## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
## 🙏 Credits
- **Fonts:** Roboto (Google), Gotham
- **Icons:** Custom EP icons
- **Framework:** MTA San Andreas
- **Developer:** Antigravity (Google Deepmind)
## 📞 Support
- **Documentation:** [SYNTAX_GUIDE.md](SYNTAX_GUIDE.md)
- **Issues:** Open an issue on GitHub
- **Discord:** [Your Discord Server]
- **Forum:** [MTA Forums Thread]
## 🗺️ Roadmap
- [ ] Markdown support
- [ ] Image upload interface
- [ ] Content templates
- [ ] Multi-language support
- [ ] Content search functionality
- [ ] Export/import pages
- [ ] Version history
- [ ] Collaborative editing
---
<div align="center">
**Made with ❤️ for the MTA community**
[⬆ Back to Top](#ep-help-system-)
</div>
