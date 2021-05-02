// ==UserScript==
// @name          Torn Layout Upgrade
// @description   See https://www.torn.com/forums.php#/p=threads&f=67&t=16219017&b=0&a=0
// @author        Sillvean [2565464]
// @include       https://www.torn.com/*
// @version       0.4
// ==/UserScript==

let savedStyles = [];

function Sleep(ms) { return new Promise(resolve => setTimeout(resolve, ms));}
function SaveStyle(el) { savedStyles.push({element: el, style: el.style}); }
function StyleElement(name, elementStyle, childrenStyle)
{
    for (let el of document.querySelectorAll(name))
    {
        SaveStyle(el);
        el.style.visibility = elementStyle.visibility;
        el.style.display = elementStyle.display;
        el.style.background = elementStyle.background;
        el.style.color = elementStyle.color;
        el.style.filter = elementStyle.filter;

        for(let child of el.querySelectorAll("*"))
        {
            SaveStyle(child);
            child.style.visibility = childrenStyle.visibility;
            child.style.display = childrenStyle.display;
            child.style.background = childrenStyle.background;
            child.style.color = childrenStyle.color;
            child.style.filter = childrenStyle.filter;
        }
    }
}
function StyleChildrenAlternately(parentName, childName, elementAStyle, elementBStyle)
{
    for (let el of document.querySelectorAll(parentName))
    {
        let i = 0;

        for(let child of el.querySelectorAll(childName))
        {
            SaveStyle(child);

            let childrenStyle = i % 2 == 0 ? elementAStyle : elementBStyle;

            child.style.visibility = childrenStyle.visibility;
            child.style.display = childrenStyle.display;
            child.style.background = childrenStyle.background;
            child.style.color = childrenStyle.color;
            child.style.filter = childrenStyle.filter;

            i++;
        }
    }
}
function MakeDark()
{
    // Make tooltip fonts white-ish
    StyleElement('.ui-tooltip', {}, {color: "#eeeeee"})
    // Disable reflections
    StyleElement('.reflection', {visibility: "hidden", display: 'none'}, {});
    // New posts distinguishing
    StyleElement('.new', {background: "#202020"}, {color: "#ffffff"});
    // Chatboxes dark
    StyleElement('.viewport_1F0WI', {background: "#333333", color: "#eeeeee"}, {});
    StyleElement('.chat-box-input_1SBQR ', {background: "#333333", color: "#eeeeee"}, {});
    StyleElement('.chat-box-input_1SBQR textarea', {background: "#444444", color: "#eeeeee"}, {background: "#333333", color: "#eeeeee"});
    StyleElement('.tt-chat-filter', {background: "#333333", color: "#eeeeee"}, {background: "#444444", color: "#eeeeee"});
    StyleChildrenAlternately('.overview_1MoPG', '.message_oP8oM  ', {background: "#333333", color: "#eeeeee"}, {background: "#444444", color: "#eeeeee"});
    StyleElement('.message_oP8oM  a', {color: "#d99400"}, {});
    // Newspaper legibility
    StyleElement('.page-template-cont', {}, {color: "#eeeeee"});
    // Personal stats table dark
    StyleElement('.removeUserButton___2UJeH', {background: "#333333", color: '#eeeeee'}, {});
    StyleElement('.user___1P_AX', {background: "#333333", color: '#eeeeee'}, {});
    StyleElement('.container___2Afjf.button___3Wipa.containerDisabled___2e8Sz', {background: "#333333", color: '#eeeeee'}, {});
    StyleElement('.inputWrap___1KIJ-.flexRow___1u0ed', {background: "#333333", color: '#eeeeee'}, {});
    StyleElement('.content___3Si_D.selectUsersCont___UjAZr', {background: "#333333", color: '#eeeeee'}, {});
    StyleElement('.title___1a5LV', {background: "#333333", color: '#eeeeee'}, {});
    // Chart
    StyleElement('.link___-uU3w', {background: "#333333"}, {});
    StyleElement('.stats___1f3ux', {}, {background: "#333333", color: "#eeeeee"});
    // Crime outcome
    StyleElement('.module-desc', {background: "#333333", color: "#eeeeee"}, {});
    // Backdrop image
    StyleElement('.custom-bg-desktop', {filter: 'invert() brightness(200%) contrast(2) opacity(0.65)'}, {});
}
function RevertStyling()
{
    for (let el of savedStyles)
    {
        el.element.style = el.style;
    }
}

async function Execute() {
    while(true)
    {
        if (document.getElementById('dark-mode-state').checked)
        {
            MakeDark();
        }
        else
        {
            RevertStyling();
        }

        await Sleep(100);
    }
}

$(window).on('load', function(){Execute();});