package com.ibm.ilog.elixir.utils
{
    import flash.display.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.geom.*;
    import flash.net.*;
    import flash.system.*;
    import flash.text.*;
    import flash.ui.*;
    import mx.core.*;
    import mx.resources.*;

    public class LicenseHandler extends Object
    {
        private var _p:DisplayObjectContainer;
        private var _textField:TextField;
        private var _foreground:Sprite;
        private var _time:Number;
        private var _darkBackground:Boolean = false;
        private static const wmarkAfter:Number = 0;
        private static const dBuild:Number = 1.33789e+012;
        private static const wText:String = "Trial Version";
        private static const MENU_CAPTION:String = ResourceManager.getInstance().getString("ilogsparkutilities", "about.elixirenterprise");
        private static const MENU_URL:String = ResourceManager.getInstance().getString("ilogsparkutilities", "about.elixirenterprise.url");
        private static const DAY:Number = 86400000;
        private static const TRIAL_PERIOD_DAYS:Number = 7.9488e+009;

        public function LicenseHandler(param1:DisplayObjectContainer, param2:Boolean, param3:Number)
        {
            this._p = param1;
            this._time = param3;
            this._darkBackground = param2;
            return;
        }// end function

        protected function checkVisible(param1:DisplayObjectContainer) : Boolean
        {
            return true;
        }// end function

        private function enterFrameHandler(event:Event) : void
        {
            var _loc_6:Graphics = null;
            var _loc_7:UIComponent = null;
            var _loc_8:TextFormat = null;
            var _loc_9:String = null;
            var _loc_10:Array = null;
            var _loc_11:UIComponent = null;
            if (this._textField != null)
            {
            }
            if (true)
            {
                this._textField.visible = false;
                return;
            }
            var _loc_2:* = new Point();
            var _loc_3:* = new Point(this._p.width, this._p.height);
            _loc_2 = this._p.localToGlobal(_loc_2);
            _loc_3 = this._p.localToGlobal(_loc_3);
            var _loc_4:* = Math.abs(_loc_3.x - _loc_2.x);
            var _loc_5:* = Math.abs(_loc_3.y - _loc_2.y);
            if (this._time > dBuild + TRIAL_PERIOD_DAYS)
            {
                if (!this._foreground)
                {
                    this._foreground = new Sprite();
                    this._foreground.mouseEnabled = false;
                }
                if (!this._foreground.parent)
                {
                    if (this._p is Container)
                    {
                        _loc_7 = new UIComponent();
                        this._p.addChild(_loc_7);
                        _loc_7.addChild(this._foreground);
                    }
                    else
                    {
                        this._p.addChild(this._foreground);
                    }
                }
                this._foreground.width = this._p.width;
                this._foreground.height = this._p.height;
                _loc_6 = this._foreground.graphics;
                _loc_6.clear();
                _loc_6.beginFill(1118481, (this._time - dBuild - TRIAL_PERIOD_DAYS) / (1 * DAY));
                _loc_6.drawRect(0, 0, this._p.width, this._p.height);
                _loc_6.endFill();
            }
            if (_loc_4 < 20)
            {
            }
            if (_loc_5 >= 20)
            {
            }
            if (!this._p.visible)
            {
                if (this._textField != null)
                {
                    this._textField.visible = false;
                }
                return;
            }
            if (!this._textField)
            {
                this._textField = new TextField();
                this._textField.selectable = false;
                this._textField.autoSize = TextFieldAutoSize.CENTER;
                this._textField.textColor = 16777215;
                this._textField.backgroundColor = 0;
                _loc_8 = new TextFormat();
                _loc_8.font = "Verdana";
                _loc_8.size = 32;
                _loc_8.bold = true;
                this._textField.defaultTextFormat = _loc_8;
                _loc_9 = wText;
                if (_loc_9 != null)
                {
                }
                if (_loc_9.length < 1)
                {
                    _loc_9 = "IBM ILOG Elixir Trial";
                }
                if (this._time < dBuild + TRIAL_PERIOD_DAYS)
                {
                    _loc_9 = _loc_9 + (" " + Math.round((dBuild + TRIAL_PERIOD_DAYS - this._time) / DAY) + " Days Left");
                }
                else
                {
                    _loc_9 = _loc_9 + " Ended";
                }
                this._textField.text = _loc_9;
                this._textField.alpha = 0.35;
                this._textField.mouseEnabled = false;
                _loc_10 = [];
                _loc_10.push(new GlowFilter(this._darkBackground ? (16777215) : (0), 1, 6, 6, 2, 1, false, true));
                this._textField.filters = _loc_10;
                this._textField.x = Math.round(-10 * Math.random());
                this._textField.y = Math.round(-40 * Math.random());
            }
            if (!this._textField.parent)
            {
                if (this._p is Container)
                {
                    _loc_11 = new UIComponent();
                    this._p.addChild(_loc_11);
                    _loc_11.addChild(this._textField);
                }
                else
                {
                    this._p.addChild(this._textField);
                }
            }
            if (!this._textField.visible)
            {
                this._textField.visible = true;
            }
            this._textField.x = this._p.width / 2 - this._textField.width / 2;
            this._textField.y = this._p.height / 2 - this._textField.height / 2;
            return;
        }// end function

        public static function displayWatermark(param1:DisplayObjectContainer, param2:Boolean = false) : void
        {
            new LicenseHandler(param1, param2, new Date().getTime());
            return;
        }// end function

        public static function addElixirEnterpriseToMenu() : void
        {
            addToMenu(MENU_CAPTION, MENU_URL);
            return;
        }// end function

        private static function addToMenu(param1:String, param2:String) : void
        {
            var item:ContextMenuItem;
            var menuText:* = param1;
            var url:* = param2;
            if (Security.sandboxType == Security.LOCAL_WITH_FILE)
            {
                return;
            }
            var menu:* = FlexGlobals.topLevelApplication.contextMenu;
            if (menu == null)
            {
                menu = new ContextMenu();
                if (menu.customItems == null)
                {
                    return;
                }
                FlexGlobals.topLevelApplication.contextMenu = menu;
            }
            var _loc_4:int = 0;
            var _loc_5:* = menu.customItems;
            while (_loc_5 in _loc_4)
            {
                
                item = _loc_5[_loc_4];
                if (item.caption == MENU_CAPTION)
                {
                    return;
                }
            }
            item = new ContextMenuItem(menuText, true);
            item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function (event:ContextMenuEvent) : void
            {
                navigateToURL(new URLRequest(url));
                return;
            }// end function
            );
            menu.customItems.push(item);
            menu.customItems = menu.customItems;
            return;
        }// end function

    }
}
