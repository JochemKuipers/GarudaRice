var plasma = getApiVersion(1)

// Center Krunner on screen - requires relogin
const krunner = ConfigFile('krunnerrc')
krunner.group = 'General'
krunner.writeEntry('FreeFloating', true);

// Change keyboard repeat delay from default 600ms to 250ms
const kbd = ConfigFile('kcminputrc')
kbd.group = 'Keyboard'
kbd.writeEntry('RepeatDelay', 250);

// Create Top Panel
const panel = new Panel
panel.alignment = "left"
panel.floating = false
panel.height = Math.round(gridUnit * 1.8);
panel.location = "top"


// The order in which the below Applets are listed will be reflected from Left to Right in the Top Panel. //

// The Kickoff launcher
var launcher = panel.addWidget("org.kde.plasma.kickoff")
launcher.currentConfigGroup = ["General"]
launcher.writeConfig("icon", "distributor-logo-garuda")
launcher.writeConfig("lengthFirstMargin", 7)
launcher.currentConfigGroup = ["Shortcuts"]
launcher.writeConfig("global", "Alt+F1")

// __WINDOW_BUTTONS__

// Window Title - Using a fork for Plasma 6 (plasma6-applets-window-title)
var title = panel.addWidget("org.kde.windowtitle")
title.currentConfigGroup = ["General"]
title.writeConfig("filterActivityInfo", false)
title.writeConfig("lengthFirstMargin", 7)
title.writeConfig("lengthMarginsLock", false)
title.writeConfig("filterByScreen", true)
title.currentConfigGroup = ["Appearance"]
title.writeConfig("altTxt", "Dr460nized KDE 🔥")
title.writeConfig("isBold", true)
title.writeConfig("visible", false)

// Window AppMenu - NOT PORTED TO PLASMA 6 YET, REPLACED BY GLOBAL MENU BELOW
//var appmenu = panel.addWidget("org.kde.windowappmenu")
//appmenu.currentConfigGroup = ["General"]
//appmenu.writeConfig("fillWidth", true)
//appmenu.writeConfig("toggleMaximizedOnDoubleClick", true)
//appmenu.writeConfig("filterByScreen", true)
//appmenu.writeConfig("spacing", 4)

// Window Global Menu - REMOVE IF WINDOW APP MENU GETS PORTED
var plasmaappmenu = panel.addWidget("org.kde.plasma.appmenu")

// Add Left Expandable Spacer
var spacer = panel.addWidget("org.kde.plasma.panelspacer")

// Digital Clock
var digitalclock = panel.addWidget("org.kde.plasma.digitalclock")
digitalclock.currentConfigGroup = ["Appearance"]
digitalclock.writeConfig("autoFontAndSize", false)
digitalclock.writeConfig("customDateFormat", "MMM d,")
digitalclock.writeConfig("dateDisplayFormat", "BesideTime")
digitalclock.writeConfig("dateFormat", "custom")
digitalclock.writeConfig("enabledCalendarPlugins", "alternatecalendar,astronomicalevents,holidaysevents")
digitalclock.writeConfig("fontFamily", "Fira Code")
digitalclock.writeConfig("fontStyleName", "Regular")
digitalclock.writeConfig("fontWeight", 400)
digitalclock.writeConfig("showWeekNumbers", true)

// Add Right Expandable Spacer
var spacer = panel.addWidget("org.kde.plasma.panelspacer")

// Panel Colorizer for Top Panel
var colorizer = panel.addWidget("luisbocanegra.panel.colorizer")
colorizer.currentConfigGroup = ["General"]
colorizer.writeConfig("globalSettings", '{"panel":{"enabled":true,"blurBehind":true,"backgroundColor":{"enabled":true,"lightnessValue":0.5,"saturationValue":0.5,"alpha":0.15,"systemColor":"alternateBackgroundColor","systemColorSet":"Window","custom":"#013eff","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1},"foregroundColor":{"enabled":false,"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"highlightColor","systemColorSet":"View","custom":"#fc0000","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1},"radius":{"enabled":false,"corner":{"topLeft":5,"topRight":5,"bottomRight":5,"bottomLeft":5}},"margin":{"enabled":false,"side":{"right":0,"left":0,"top":0,"bottom":0}},"padding":{"enabled":false,"side":{"right":0,"left":0,"top":0,"bottom":0}},"border":{"enabled":false,"customSides":false,"custom":{"widths":{"left":0,"bottom":3,"right":0,"top":0},"margin":{"enabled":false,"side":{"right":0,"left":0,"top":0,"bottom":0}},"radius":{"enabled":false,"corner":{"topLeft":5,"topRight":5,"bottomRight":5,"bottomLeft":5}}},"width":0,"color":{"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"highlightColor","systemColorSet":"View","custom":"#ff6c06","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1,"enabled":true}},"shadow":{"background":{"enabled":false,"color":{"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"backgroundColor","systemColorSet":"View","custom":"#282828","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1,"enabled":false},"size":5,"xOffset":0,"yOffset":0},"foreground":{"enabled":false,"color":{"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"backgroundColor","systemColorSet":"View","custom":"#282828","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1,"enabled":true},"size":5,"xOffset":0,"yOffset":0}},"unfiedBackground":{"org.kde.plasma.digitalclock":0}},"widgets":{"enabled":true,"blurBehind":false,"backgroundColor":{"enabled":false,"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"backgroundColor","systemColorSet":"View","custom":"#013eff","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1},"foregroundColor":{"enabled":false,"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"highlightColor","systemColorSet":"View","custom":"#fc0000","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1},"radius":{"enabled":false,"corner":{"topLeft":5,"topRight":5,"bottomRight":5,"bottomLeft":5}},"margin":{"enabled":false,"side":{"right":0,"left":0,"top":0,"bottom":0}},"spacing":4,"border":{"enabled":false,"customSides":false,"custom":{"widths":{"left":0,"bottom":3,"right":0,"top":0},"margin":{"enabled":false,"side":{"right":0,"left":0,"top":0,"bottom":0}},"radius":{"enabled":false,"corner":{"topLeft":5,"topRight":5,"bottomRight":5,"bottomLeft":5}}},"width":0,"color":{"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"highlightColor","systemColorSet":"View","custom":"#ff6c06","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1,"enabled":true}},"shadow":{"background":{"enabled":false,"color":{"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"backgroundColor","systemColorSet":"View","custom":"#282828","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1,"enabled":false},"size":5,"xOffset":0,"yOffset":0},"foreground":{"enabled":false,"color":{"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"backgroundColor","systemColorSet":"View","custom":"#282828","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1,"enabled":false},"size":5,"xOffset":0,"yOffset":0}},"unfiedBackground":{"org.kde.plasma.digitalclock":0}},"trayWidgets":{"enabled":false,"blurBehind":false,"backgroundColor":{"enabled":false,"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"backgroundColor","systemColorSet":"View","custom":"#013eff","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1},"foregroundColor":{"enabled":false,"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"highlightColor","systemColorSet":"View","custom":"#fc0000","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1},"radius":{"enabled":false,"corner":{"topLeft":5,"topRight":5,"bottomRight":5,"bottomLeft":5}},"margin":{"enabled":false,"side":{"right":0,"left":0,"top":0,"bottom":0}},"border":{"enabled":false,"customSides":false,"custom":{"widths":{"left":0,"bottom":3,"right":0,"top":0},"margin":{"enabled":false,"side":{"right":0,"left":0,"top":0,"bottom":0}},"radius":{"enabled":false,"corner":{"topLeft":5,"topRight":5,"bottomRight":5,"bottomLeft":5}}},"width":0,"color":{"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"highlightColor","systemColorSet":"View","custom":"#ff6c06","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1,"enabled":true}},"shadow":{"background":{"enabled":false,"color":{"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"backgroundColor","systemColorSet":"View","custom":"#282828","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1,"enabled":true},"size":5,"xOffset":0,"yOffset":0},"foreground":{"enabled":false,"color":{"lightnessValue":0.5,"saturationValue":0.5,"alpha":1,"systemColor":"backgroundColor","systemColorSet":"View","custom":"#282828","list":["#ED8796","#A6DA95","#EED49F","#8AADF4","#F5BDE6","#8BD5CA","#f5a97f"],"followColor":0,"saturationEnabled":false,"lightnessEnabled":false,"animation":{"enabled":false,"interval":3000,"smoothing":800},"sourceType":1,"enabled":true},"size":5,"xOffset":0,"yOffset":0}},"unfiedBackground":{"org.kde.plasma.digitalclock":0}},"nativePanelBackground":{"enabled":true,"opacity":0},"forceForegroundColor":{"widgets":{"com.github.antroids.application-title-bar":{"method":{"mask":false,"multiEffect":false},"reload":true},"org.kde.plasma.appmenu":{"method":{"mask":false,"multiEffect":false},"reload":true}},"reloadInterval":250},"stockPanelSettings":{"position":3,"alignment":2,"width":2,"visibility":3,"opacity":2,"floating":false,"lengthMode":{"enabled":false,"value":"fill"},"thickness":{"enabled":false,"value":48},"visible":{"enabled":false,"value":true}},"configurationOverrides":{"overrides":{},"associations":{}},"overrideAssociations":{},"unifiedBackground":{}}')
colorizer.writeConfig("hideWidget", true)
colorizer.writeConfig("lastPreset", "__COLORIZER_ROOT__/contents/ui/presets/Dr460nized Top Panel")
colorizer.writeConfig("presetAutoloading", '{"enabled":true,"touchingWindow":"__COLORIZER_ROOT__/contents/ui/presets/Dr460nized Top Panel Interaction","maximized":"__COLORIZER_ROOT__/contents/ui/presets/Dr460nized Top Panel Interaction","normal":"__COLORIZER_ROOT__/contents/ui/presets/Dr460nized Top Panel"}')

// System Tray
var systray = panel.addWidget("org.kde.plasma.systemtray")
systray.currentConfigGroup = ["General"]
// In Plasma 6, 'scaleIconsToFit' is the boolean that toggles
// between "Small" (false) and "Scale with Panel height" (true)
systray.writeConfig("scaleIconsToFit", true)
systray.writeConfig("iconSize", 0) // Optional: If you want to ensure it doesn't default to a tiny fixed size

// User Switcher (plasma-addons; skip quietly if missing on the distro)
try {
  var switcher = panel.addWidget("org.kde.plasma.userswitcher")
  switcher.currentConfigGroup = ["General"]
  switcher.writeConfig("showFace", true)
  switcher.writeConfig("showName", false)
  switcher.writeConfig("showTechnicalInfo", true)
} catch (e) { /* optional */ }

// End of Top Panel creation //
