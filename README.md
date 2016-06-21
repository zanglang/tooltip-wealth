TooltipWealth (originally TinyTipWealth) is an Ace3 module that lets you sneakily inspect how much gold your mouseover target has made so far using the Achievement API.

Also available at: [Wowace](http://www.wowace.com/addons/tinytip-wealth/).

## Features

* Display most gold ever owned (default)
* Display total gold acquired - may be used to indicate the economic prowess of a character, but is usually wildly inflated for the wealth owned by auction house players as they tend to have very high income and expenditure.
* Display average gold earned by day
* Disable for opposite faction
* Disable when in combat
* Disable when not in major city
* Show wealth as coins or plain text (e.g. 1g 10s)
* Currently tested with: [TinyTip](http://wow.curse.com/downloads/wow-addons/details/tiny-tip.aspx), [TipTac](http://wow.curse.com/downloads/wow-addons/details/tip-tac.aspx), [TipTop](http://www.wowinterface.com/downloads/info10627-TipTop.html), [CowTip](http://wow.curse.com/downloads/wow-addons/details/cowtip.aspx), normal game tooltip

## It's not working?

Try mouseovering your target carefully. If you quickly move your cursor over a bunch of people, the addon can only query the first person you've mouseovered; due to the limitation of Blizzard's API and the server's generally slow response time, by the time we've got the wealth results back from the server your cursor is likely already on a different person, so ToolTipWealth will have to discard the data.

## Warning

**!!! Some might consider the use of this addon to be an intrusion of privacy, please do not abuse it for harassing or intimidating other players. !!!**
