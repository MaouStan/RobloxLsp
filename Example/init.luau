--[[
    ScriptLoader - Roblox Script Template/Loader
    Based on SSL-VulnX M.lua pattern

    Usage:
        loadstring(game:HttpGet("PATH/TO/init.luau"))()

    Or require() locally:
        local ScriptLoader = loadfile("Utils/ScriptLoader/init.luau")
        ScriptLoader()

    After loading, GG (super global) environment is available
    with all services, functions, and player references.

    Optional AssetStorage Modules (load via GG.include("ModuleName")):
        - "Files": File system utilities (Continue, ListFrom, WriteFrom, ConvertTo, RepairTbl)
        - "Error405": Discord webhook error reporting (sendWebhook, configsToEmbeds)
        - "SensitiveService": Function hooking utilities (SLow_ForceSelfThisFunction, etc.)
        - "QueueService": Teleport queue management (Q_UploadFkey, Q_Connect, etc.)

    Example:
        GG.include("Files")  -- Loads file system utilities
        GG.FileSys:WriteFrom("MyFolder", "config.json", data)
]]

--!nolint

------------- CREDITS -------------

--[[
     _      ___         ____  ______
    | | /| / (_)__  ___/ / / / /  _/
    | |/ |/ / / _ \/ _  / /_/ // /
    |__/|__/_/_//_/\_,_/\____/___/

    v1.6.62  |  2025-12-09  |  Roblox UI Library for scripts

    Author: Footagesus ( Footages, .ftgs, oftgs )
    Github: https://github.com/Footagesus/WindUI
    License: MIT

    ScriptLoader Template
    v1.0  |  2026-01-01  |  Based on SSL-VulnX M.lua

    Extracted and modularized by:
    https://github.com/MaouStan/Roblox
]]

------------- Config -------------

-- User-configurable settings (can be overridden before loading)
LoaderSettings = LoaderSettings or {};
LoaderSettings.ExecutedByUser = true;

------------- Inline Sections (Embedded) -------------

-- These sections are embedded for single-file distribution
-- Comment these out if using external section files

------------- Game Load -------------

if not game:IsLoaded() then
    game.Loaded:Wait();
end;

-- Anti-reexecute checks
if loaded then
    return warn("[ScriptLoader] : Script already loaded.");
elseif loaded2 then
    return warn("[ScriptLoader] : This script can't be re-execute.");
end;

if LSecureLoad and LSecureUI and Functions then
    return LSecureLoad();
elseif InKey then
    return InKey();
end;

if ReplicatedFirst_lc and API_Only then
    return warn("[ScriptLoader] : Loaded via API only mode");
end;

------------- Super Global ----------

GG = (getgenv and getgenv()) or _G or shared or false;

if not GG then
    return game:GetService("Players").LocalPlayer:Kick("GG not found.");
end;

if not isfolder or not isfile or not makefolder or not writefile or not readfile then
    return game:GetService("Players").LocalPlayer:Kick("Executor doesn't support file system.");
end;

GG.GG = GG;

GG.LoaderSettings = (LoaderSettings and LoaderSettings.ExecutedByUser and LoaderSettings) or {
    BadNetwork = false;
    AllowCache = true;
    AllowKickWithError = false;
    AllowPlayerTab = true;
    AllowAI = true;
    AllowAddOn = true;
    AllowVULX_pvCMD = true;
    AllowServer_Customization = false;
};

-- TheMimicLoader settings from M.lua
LoaderSettings.TheMimicLoader = LoaderSettings.TheMimicLoader or {
    Load_Sections = true;
    Load_WithPlaceID_Checks = false;
};

GG.GameId = game.GameId;
GG.PlaceId = game.PlaceId;

------------- OBF Fixer -------------

GG.LPH_NO_VIRTUALIZE = function(...) return ... end;
GG.IB_NO_VIRTUALIZE = function(...) return ... end;

------------- Replicated First -------------

if not ReplicatedFirst_lc then
    GG.setc = setclipboard or toclipboard or function(...) return warn(...) end;

    GG.getinfo = getinfo or debug.getinfo;
    GG.clonefunction = clonefunction or clonefunc;
    GG.cloneref = cloneref or clonereference;

    if not getinfo then
        return game:GetService("Players").LocalPlayer:Kick("Executor doesn't have getinfo.");
    end;
    if clonefunction and getinfo(clonefunction).what == "Lua" then
        GG.clonefunction = function(...) return ... end;
    end;
    if cloneref and getinfo(cloneref).what == "Lua" then
        GG.cloneref = function(...) return ... end;
    end;

    GG.base64encode = base64encode or (crypt and crypt.base64encode);
    GG.base64decode = base64decode or (crypt and crypt.base64decode);
    GG.GetService = clonefunction(game.GetService);
    GG.getinfo = (getinfo and clonefunction(getinfo)) or (debug.getinfo and clonefunction(debug.getinfo));
    GG.pcall = clonefunction(pcall);

    GG.tble = table;
    GG.tk = task;
    GG.str = string;
    GG.mmaths = math;
    GG.Col3 = Color3;
    GG.BCol = BrickColor;
    GG.Reg3 = Region3;
    GG.Instance = Instance;
    GG.UDim2 = UDim2;
    GG.Font = Font;
    GG.coru = coroutine;
    GG.bff = buffer;
    GG.pir = pairs;
    GG.ipir = ipairs;

    -- Coroutine aliases
    GG.co = coroutine;
    GG.cocreate = coroutine.create;
    GG.coresume = coroutine.resume;
    GG.costatus = coroutine.status;
    GG.coyield = coroutine.yield;
    GG.cowrap = coroutine.wrap;
    GG.corunning = coroutine.running;
    GG.coclose = coroutine.close;

    -- Full SecureEnv (comprehensive built-in functions from M.lua)
    GG.SecureEnv = {
        -- Debug library functions
        dumpheap = dumpheap or debug.dumpheap;
        getconstants = getconstants or debug.getconstants;
        getproto = getproto or debug.getproto;
        setmemorycategory = setmemorycategory or debug.setmemorycategory;
        profilebegin = profilebegin or debug.profilebegin;
        loadmodule = loadmodule or debug.loadmodule;
        traceback = traceback or debug.traceback;
        getinfo = getinfo or debug.getinfo;
        getstack = getstack or debug.getstack;
        isvalidlevel = isvalidlevel or debug.isvalidlevel;
        getupvalues = getupvalues or debug.getupvalues;
        getconstant = getconstant or debug.getconstant;
        getfenv = getfenv or debug.getfenv;
        getupvalue = getupvalue or debug.getupvalue;
        getmemorycategory = getmemorycategory or debug.getmemorycategory;
        resetmemorycategory = resetmemorycategory or debug.resetmemorycategory;
        getprotos = getprotos or debug.getprotos;
        dumpcodesize = dumpcodesize or debug.dumpcodesize;
        setstack = setstack or debug.setstack;
        profileend = profileend or debug.profileend;
        dumprefs = dumprefs or debug.dumprefs;
        validlevel = validlevel or debug.validlevel;
        setupvalue = setupvalue or debug.setupvalue;
        setconstant = setconstant or debug.setconstant;
        getregistry = getregistry or debug.getregistry;
        info = info or debug.info;

        -- Legacy wait functions
        wait = wait;
        delay = delay;
        spawn = spawn;
        tick = tick;

        -- Type conversions
        tostring = tostring;
        tos = tostring;
        tonumber = tonumber;
        ton = tonumber;

        -- Table functions
        tablein = tble.insert;
        tablecl = tble.clear;
        tablef = tble.find;
        tsort = tble.sort;
        tconcat = tble.concat;
        tunpack = tble.unpack;
        tabler = tble.remove;
        tEach = tble.foreach;

        -- Random
        RNew = Random.new;

        -- Task functions
        twait = tk.wait;
        tdefer = tk.tdefer;
        tspawn = tk.spawn;
        tcancel = tk.cancel;
        tdelay = task.delay;
        tdesyn = tk.desynchronize;
        tsyn = tk.synchronize;

        -- String functions
        strgsub = str.gsub;
        strsub = str.sub;
        strfind = str.find;
        strlen = str.len;
        strchar = str.char;
        strbyte = str.byte;
        strsplit = str.split;
        strmatch = str.match;
        strgmatch = str.gmatch;
        strupper = str.upper;
        strlower = str.lower;
        strformat = str.format;
        strpack = str.pack;
        strpacksize = str.packsize;
        strreverse = str.reverse;
        strunpack = str.unpack;
        strrep = str.rep;

        -- Math functions
        mlog = mmaths.log;
        mldexp = mmaths.ldexp;
        mdeg = mmaths.deg;
        mcosh = mmaths.cosh;
        mround = mmaths.round;
        mrandom = mmaths.random;
        mfrexp = mmaths.frexp;
        mtanh = mmaths.tanh;
        mfloor = mmaths.floor;
        mmax = mmaths.max;
        msqrt = mmaths.sqrt;
        mmodf = mmaths.modf;
        mhuge = mmaths.huge;
        mpow = mmaths.pow;
        macos = mmaths.acos;
        mtan = mmaths.tan;
        mcos = mmaths.cos;
        mpi = mmaths.pi;
        matan = mmaths.atan;
        mmap = mmaths.map;
        msign = mmaths.sign;
        mceil = mmaths.ceil;
        mclamp = mmaths.clamp;
        mnoise = mmaths.noise;
        mabs = mmaths.abs;
        mexp = mmaths.exp;
        msinh = mmaths.sinh;
        masin = mmaths.asin;
        mmin = mmaths.min;
        mrandomseed = mmaths.randomseed;
        mfmod = mmaths.fmod;
        mrad = mmaths.rad;
        matan2 = mmaths.atan2;
        mlog10 = mmaths.log10;
        msin = mmaths.sin;
        mlerp = mmaths.lerp;

        -- Color3 functions
        fromRGB = Color3.fromRGB;
        fromHex = Col3.fromHex;
        fromHSV = Col3.fromHSV;
        toHSV = Col3.toHSV;
        Col3new = Col3.new;

        -- BrickColor
        BCol = BrickColor;
        BBlue = BCol.Blue;
        BWhite = BCol.White;
        BYellow = BCol.Yellow;
        BRed = BCol.Red;
        BGray = BCol.Gray;
        Bpalette = BCol.palette;
        BNew = BCol.New;
        BBlack = BCol.Black;
        BGreen = BCol.Green;
        BRandom = BCol.Random;
        BDarkGray = BCol.DarkGray;
        Brandom = BCol.random;
        Bnew = BCol.new;

        -- Font
        FfromId = Font.fromId;
        FfromEnum = Font.fromEnum;
        FfromName = Font.fromName;
        Fnew = Font.new;

        -- Region3
        Regnew = Reg3.new;

        -- TweenInfo
        TwInfo = TweenInfo.new;

        -- Rect
        Rectn = Rect.new;

        -- Vector & CFrame
        Vec3 = Vector3.new;
        Vec2 = Vector2.new;
        CF = CFrame.new;
        CFAg = CFrame.Angles;
        CFLook = CFrame.lookAt;
        CFMat = CFrame.fromMatrix;

        -- Iterators
        pir = pairs;
        ipir = ipairs;
        ipairs = ipairs;
        next = next;

        -- Pcall variants
        pcal = pcall;
        xpcal = xpcall;
        ypcal = ypcall;

        -- Instance
        Instancen = Instance.new;
        fromExisting = Instance.fromExisting;

        -- UDim2
        Dim2 = UDim2.new;
        Dim2Off = UDim2.fromOffset;
        Dim2Scale = UDim2.fromScale;

        -- UDim
        Dim = UDim.new;

        -- Sequences
        NSnew = NumberSequence.new;
        NSKnew = NumberSequenceKeypoint.new;
        CSnew = ColorSequence.new;
        CSKnew = ColorSequenceKeypoint.new;

        -- Buffer functions
        breadf64 = bff and bff.readf64;
        breadu32 = bff and bff.readu32;
        btostring = bff and bff.tostring;
        breadi8 = bff and bff.readi8;
        breadu16 = bff and bff.readu16;
        bcopy = bff and bff.copy;
        breadu8 = bff and bff.readu8;
        bwritebits = bff and bff.writebits;
        bwritei16 = bff and bff.writei16;
        bwriteu16 = bff and bff.writeu16;
        bfromstring = bff and bff.fromstring;
        bwritef32 = bff and bff.writef32;
        breadi32 = bff and bff.readi32;
        bfill = bff and bff.fill;
        bwriteu32 = bff and bff.writeu32;
        bwriteu8 = bff and bff.writeu8;
        bcreate = bff and bff.create;
        bwritestring = bff and bff.writestring;
        bwritei8 = bff and bff.writei8;
        breadbits = bff and bff.readbits;
        breadi16 = bff and bff.readi16;
        bwritef64 = bff and bff.writef64;
        blen = bff and bff.len;
        bwritei32 = bff and bff.writei32;
        breadstring = bff and bff.readstring;
        breadf32 = bff and bff.readf32;

        -- Hooking functions
        LowerC = hookfunction or hookfunc;
        UpperC = hookmetamethod;
        ResetC = restorefunction;

        -- OS functions
        oclock = os.clock;
        odiff = os.difftime;
        otime = os.time;
        odate = os.date;

        -- Executor-specific
        queueOT = queueonteleport or queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or on_teleport;
        Request = http_request or request;
    };

    GG.SecureEnvS = {
        ProximityPromptService = "ProximityPromptService";
        VirtualInputManager = "VirtualInputManager";
        RbxAnalyticsService = "RbxAnalyticsService";
        LocalizationService = "LocalizationService";
        CollectionService = "CollectionService";
        UserInputService = "UserInputService";
        TeleportService = "TeleportService";
        TextService = "TextChatService";
        TweenService = "TweenService";
        HttpService = "HttpService";
        StarterGui = "StarterGui";
        GuiService = "GuiService";
        R = "ReplicatedStorage";
        SoundS = "SoundService";
        TestS = "TestService";
        VU = "VirtualUser";
        H = "RunService";
        W = "Workspace";
        L = "Lighting";
        P = "Players";
        C = "CoreGui";
    };

    GG.ReplicatedFirst_lc = true;
end;

------------- Global API Setup -------------

GG.ExecName = (identifyexecutor and identifyexecutor()) or "nil";
GG.Load_Icona = false;
GG.ScriptCache = {};
GG.Threads = {};

ScriptCache.gcF = {};
ScriptCache.userIdentify = {
    is_loaded_lc = false;
    device = nil;
    is_Internal = nil;
    is_executor_WhiteList = nil;
    gcF = false;
    unc_infos = false;
};
ScriptCache.AutoConfigPathCache = {};

GG.include = function(globalOrName:string, as:string)
    if not AssetStorage then return; end;
    local fn = nil;
    if type(globalOrName) == 'function' then
        fn = globalOrName;
    elseif type(globalOrName) == 'string' then
        local found = AssetStorage[globalOrName];
        if type(found) ~= 'function' then return; end;
        fn = found;
    else
        return;
    end;
    local result = fn();
    if result and as then
        GG[as] = result;
        return;
    else
        return result;
    end;
end;

ScriptCache.userIdentify.gcF = {};
ScriptCache.userIdentify.gcF.is_Internal = function(...) return GG.ScriptCache.userIdentify.is_Internal end;
ScriptCache.userIdentify.gcF.get_device = function(...) return GG.ScriptCache.userIdentify.device end;
ScriptCache.userIdentify.gcF.is_exec_white = function(...) return GG.ScriptCache.userIdentify.is_executor_WhiteList end;
ScriptCache.userIdentify.gcF.getunc_infos = function(...) return GG.ScriptCache.userIdentify.unc_infos end;

ScriptCache.userIdentify.secureEnv = function(index: string, env: (...any) -> nil): nil
    if clonefunction and env and type(env) == 'function' then
        GG[index] = clonefunction(env);
    else
        GG[index] = env;
    end;
end;

ScriptCache.userIdentify.secureEnvS = function(index: string, service: string): nil
    if cloneref and service then
        GG[index] = cloneref(GetService(game, service));
    else
        GG[index] = service;
    end;
end;

------------- LC Loader -------------

for i = 1, 3 do
    local GlobalOneRunCall, GlobalOneRunError = pcall(function()
        table.foreach(GG.SecureEnv, GG.ScriptCache.userIdentify.secureEnv);
        table.foreach(GG.SecureEnvS, GG.ScriptCache.userIdentify.secureEnvS);

        local P = game:GetService("Players");
        local W = game:GetService("Workspace");
        local HttpService = game:GetService("HttpService");
        local RbxAnalyticsService = game:GetService("RbxAnalyticsService");
        local TweenService = game:GetService("TweenService");
        local UserInputService = game:GetService("UserInputService");

        GG.SecureEnvR = {
            HttpGet = game.HttpGet;
            EnCodeJ = HttpService.JSONEncode;
            DeCodeJ = HttpService.JSONDecode;
            GenerateGUID = HttpService.GenerateGUID;
            GetClientId = RbxAnalyticsService.GetClientId;
            GetPivot = W.GetPivot;
            PivotTo = W.PivotTo;
            FindPartsInRegion3WithIgnoreList = W.FindPartsInRegion3WithIgnoreList;
            IsA = game.IsA;
            Clone = game.Clone;
            GetFullName = game.GetFullName;
            IsDescendantOf = game.IsDescendantOf;
            PropChangeSignal = game.GetPropertyChangedSignal;
            AttChangeSignal = game.GetAttributeChangedSignal;
            GetPlayerFromCharacter = P.GetPlayerFromCharacter;
            GetNetworkPing = P.LocalPlayer.GetNetworkPing;
            GetPlayers = P.GetPlayers;
            TwCreate = TweenService.Create;
            GetAttribute = game.GetAttribute;
            SetAttribute = game.SetAttribute;
            WaitForChild = game.WaitForChild;
            FindFirstChild = game.FindFirstChild;
            FindFirstChildOfClass = game.FindFirstChildOfClass;
            FindFirstChildWhichIsA = game.FindFirstChildWhichIsA;
            FindFirstAncestor = game.FindFirstAncestor;
            FindFirstAncestorOfClass = game.FindFirstAncestorOfClass;
            FindFirstAncestorWhichIsA = game.FindFirstAncestorWhichIsA;
            GetChildren = game.GetChildren;
            GetDescendants = game.GetDescendants;
            Destroy = game.Destroy;
            Kick = P.LocalPlayer.Kick;
            GetServerTimeNow = W.GetServerTimeNow;
        };

        table.foreach(GG.SecureEnvR, GG.ScriptCache.userIdentify.secureEnv);

        -- Instance method wrappers (convert Method(obj, ...) to obj:Method(...))
        GG.IsA = function(obj: any, className: string): boolean
            local objType = typeof(obj);
            return objType == "Instance" and obj:IsA(className) or objType == className;
        end;

        GG.Clone = function(obj: Instance): Instance?
            return typeof(obj) == "Instance" and obj:Clone();
        end;

        GG.GetFullName = function(obj: Instance): string
            return typeof(obj) == "Instance" and obj:GetFullName() or "";
        end;

        GG.IsDescendantOf = function(obj: Instance, ancestor: Instance): boolean
            return typeof(obj) == "Instance" and obj:IsDescendantOf(ancestor);
        end;

        GG.GetAttribute = function(obj: Instance, name: string): any
            return typeof(obj) == "Instance" and obj:GetAttribute(name);
        end;

        GG.SetAttribute = function(obj: Instance, name: string, value: any): boolean
            if typeof(obj) == "Instance" then
                obj:SetAttribute(name, value);
                return true;
            end;
            return false;
        end;

        GG.WaitForChild = function(obj: Instance, name: string, timeout: number?): Instance
            return typeof(obj) == "Instance" and obj:WaitForChild(name, timeout);
        end;

        GG.FindFirstChild = function(obj: Instance, name: string?, recursive: boolean?): Instance?
            return typeof(obj) == "Instance" and obj:FindFirstChild(name, recursive);
        end;

        GG.FindFirstChildOfClass = function(obj: Instance, className: string): Instance?
            return typeof(obj) == "Instance" and obj:FindFirstChildOfClass(className);
        end;

        GG.FindFirstChildWhichIsA = function(obj: Instance, className: string, recursive: boolean?): Instance?
            return typeof(obj) == "Instance" and obj:FindFirstChildWhichIsA(className, recursive);
        end;

        GG.FindFirstAncestor = function(obj: Instance, name: string?): Instance?
            return typeof(obj) == "Instance" and obj:FindFirstAncestor(name);
        end;

        GG.FindFirstAncestorOfClass = function(obj: Instance, className: string): Instance?
            return typeof(obj) == "Instance" and obj:FindFirstAncestorOfClass(className);
        end;

        GG.FindFirstAncestorWhichIsA = function(obj: Instance, className: string): Instance?
            return typeof(obj) == "Instance" and obj:FindFirstAncestorWhichIsA(className);
        end;

        GG.GetChildren = function(obj: Instance): {Instance}
            return typeof(obj) == "Instance" and obj:GetChildren() or {};
        end;

        GG.GetDescendants = function(obj: Instance): {Instance}
            return typeof(obj) == "Instance" and obj:GetDescendants() or {};
        end;

        GG.Destroy = function(obj: Instance): nil
            if typeof(obj) == "Instance" then
                obj:Destroy();
            end;
        end;

        GG.GetPivot = function(obj: Model): CFrame
            return typeof(obj) == "Instance" and obj:GetPivot() or CFrame.new();
        end;

        GG.PivotTo = function(obj: Model, pivotCFrame: CFrame): nil
            if typeof(obj) == "Instance" then
                obj:PivotTo(pivotCFrame);
            end;
        end;

        GG.PropChangeSignal = function(obj: Instance, property: string): RBXScriptSignal
            return typeof(obj) == "Instance" and obj:GetPropertyChangedSignal(property);
        end;

        GG.AttChangeSignal = function(obj: Instance, attribute: string): RBXScriptSignal
            return typeof(obj) == "Instance" and obj:GetAttributeChangedSignal(attribute);
        end;

        GG.selff = P.LocalPlayer;
        GG.Cam = W.CurrentCamera;
        GG.cmdm = GG.selff:GetMouse();
        GG.PSG = GG.selff:WaitForChild("PlayerGui", 999);
        GG.PlayerScripts = GG.selff:WaitForChild("PlayerScripts", 999);
        GG.selc = GG.selff.Character or GG.selff.CharacterAdded:Wait();
        GG.Backpack = GG.selff:WaitForChild("Backpack");
        GG.RNG = Random.new();
        GG.HumRSelf = GG.selc and (GG.selc.PrimaryPart or GG.selc:FindFirstChild("HumanoidRootPart"));
        GG.HumSelf = GG.FindFirstChildOfClass(GG.selc, "Humanoid");
        GG.GravitySelf = W.Gravity;
        -- on character added
        GG.selff.CharacterAdded:Connect(function(char)
            GG.selc = char;
            -- loop until HumanoidRootPart exists
            repeat
                twait();
                GG.HumRSelf = char.PrimaryPart or GG.FindFirstChild(char, "HumanoidRootPart");
                GG.HumSelf = GG.FindFirstChildOfClass(char, "Humanoid");
            until GG.HumRSelf;
            print("[ScriptLoader] : Character loaded.");
        end);
    end);

    if GlobalOneRunCall then
        GG.ScriptCache.userIdentify.is_loaded_lc = true;
        break;
    else
        if i >= 3 then
            local errorMsg = "ScriptLoader error: " .. tostring(GlobalOneRunError);
            return GG.LoaderSettings.AllowKickWithError and warn(errorMsg) or game:GetService("Players").LocalPlayer:Kick(errorMsg);
        end;
    end;
end;

GG.newcclosure = newcclosure or function(...) return ... end;
GG.newlclosure = newlclosure or function(...) return ... end;

-- Fallback: Ensure GG.IsA is always defined (in case LC Loader didn't set it)
if not GG.IsA or type(GG.IsA) ~= "function" then
    GG.IsA = function(obj: any, className: string): boolean
        local objType = typeof(obj);
        if objType == "Instance" then
            return obj:IsA(className);
        end;
        return objType == className;
    end;
end;

-- Device detection
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    ScriptCache.userIdentify.device = "Mobile";
elseif UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
    ScriptCache.userIdentify.device = "PC";
elseif UserInputService.GamepadEnabled then
    ScriptCache.userIdentify.device = "Console";
else
    ScriptCache.userIdentify.device = "Unknown";
end;

-- Uncapped function detection
ScriptCache.userIdentify.unc_infos = {
    fireproximityprompt = (fireproximityprompt and getinfo(fireproximityprompt).what) or false;
    firetouchinterest = (firetouchinterest and getinfo(firetouchinterest).what) or false;
    isnetworkowner = (isnetworkowner and getinfo(isnetworkowner).what) or false;
    require = (require and getinfo(require).what) or false;
    request = (Request and getinfo(Request).what) or false;
    getgc = (getgc and getinfo(getgc).what) or false;
};

GG.loadsource = function(source:string):any
    for attempt = 1, 3 do
        local suc, res = pcal(function()
            return loadstring(source)();
        end);
        if suc then
            return res;
        else
            warn(strformat("[ScriptLoader] : Attempt %d : %s", attempt, tos(res)));
            twait();
        end;
    end;
end;

-- loadScriptFromCache from M.lua - Cache system for loading scripts from GitHub
GG.loadScriptFromCache = function(srcName, fileName, noload, custom_time, is_ignore)
    if LoaderSettings.AllowCache then
        if not isfolder("FlowXS") then
            makefolder("FlowXS");
        end;

        local CD = custom_time or 600;
        local versionFile = "FlowXSVersion.json";
        local cacheFile = "FlowXS/" .. tos(fileName);
        local no_write = is_ignore;

        GG.ALLVersion = ALLVersion or {};
        ALLVersion[tos(fileName)] = ALLVersion[tos(fileName)] or tos(tick());

        local function refresh()
            local source = GG.HttpGet(game, srcName);
            ALLVersion[tos(fileName)] = tos(tick());
            writefile(cacheFile, source);
            if not no_write then
                writefile(versionFile, GG.EnCodeJ(GG.HttpService, ALLVersion));
            end;
            return source;
        end;

        if tick() - ton(ALLVersion[tos(fileName)]) >= CD then
            warn("[ScriptLoader] : Loaded " .. fileName .. " from GitHub via auto-update");
            local s = refresh();
            return noload and s or loadsource(s);
        end;

        local cachedSource = isfile(cacheFile) and readfile(cacheFile);
        if not cachedSource or not isfile(versionFile) then
            warn("[ScriptLoader] : Loaded " .. fileName .. " from GitHub");
            local s = refresh();
            return noload and s or loadsource(s);
        end;

        warn("[ScriptLoader] : Loaded " .. fileName .. " from device and NOT GitHub");
        return noload and cachedSource or loadsource(cachedSource);
    else
        local source = GG.HttpGet(game, srcName);
        warn("[ScriptLoader] : Loaded " .. fileName .. " via nowrite.2");
        return noload and source or loadsource(source);
    end;
end;

-- error_handler from M.lua
GG.error_handler = function(...)
    return warn("[ScriptLoader] : Error : " .. ...);
end;

-- CONTROL from M.lua - Mobile control module
GG.CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0};
if GG.ScriptCache.userIdentify.device == "Mobile" then
    pcal(function()
        GG.controlModule = require(GG.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"));
    end);
end;

------------- Common Utilities (CommonF) -------------

-- Distance calculator
GG.dist = function(position: Vector3): number
    return GG.selff:DistanceFromCharacter(position);
end;

GG.rootHum = function(character: Model): (BasePart?, Humanoid?)
    if not character then return nil, nil; end;
    local humanoid: Humanoid = GG.FindFirstChildOfClass(character, "Humanoid");
    local rootPart: BasePart = character.PrimaryPart or GG.FindFirstChild(character, "HumanoidRootPart") or GG.FindFirstChildOfClass(character, "BasePart");
    return rootPart, humanoid;
end;

-- Serialize table to string (for array-like tables)
GG.tableToString = function(tbl: {[any]: any}, name: string?): string
    name = name or "tbl";
    local function serialize(t: {[any]: any}, indent: number?): string
        indent = indent or 0;
        local str = "{ ";
        for k, v in ipairs(t) do
            local key: string = nil;
            if type(k) == "string" then
                key = strformat("[%q]", k);
            else
                key = "[" .. tos(k) .. "]";
            end;

            local value: string;
            if type(v) == "table" then
                value = serialize(v, indent + 2);
            elseif type(v) == "string" then
                value = strformat("%q", v);
            else
                value = tos(v);
            end;
            str = str .. key .. " = " .. value .. ", ";
        end;
        str = str .. "}";
        return str;
    end;

    return name .. " = " .. serialize(tbl) .. ";";
end;

-- Serialize configs table to string (for all key types)
GG.configsToString = function(configs: {[any]: any}): string
    local function serialize(tbl: {[any]: any}, indent: string?): string
        indent = indent or "";
        local result = "{\n";
        for k, v in pairs(tbl) do
            local key = (typeof(k) == "string") and strformat("[%q]", k) or "[" .. tos(k) .. "]";
            if typeof(v) == "table" then
                result ..= indent .. "    " .. key .. " = " .. serialize(v, indent .. "    ") .. ";\n";
            elseif typeof(v) == "string" then
                result ..= indent .. "    " .. key .. " = " .. strformat("%q", v) .. ";\n";
            else
                result ..= indent .. "    " .. key .. " = " .. tos(v) .. ";\n";
            end;
        end;
        result ..= indent .. "}";
        return result;
    end;
    local exported = "getgenv().Configs = " .. serialize(configs);
    return exported;
end;

-- Serialize table to JSON string (optimized with cached HttpService)
GG.tableToJSON = function(tbl: {[any]: any}): string
    GG._HttpServiceCache = GG._HttpServiceCache or GG.GetService(game, "HttpService");
    return GG._HttpServiceCache:JSONEncode(tbl);
end;

-- Serialize JSON string to table (optimized with cached HttpService)
GG.JSONToTable = function(jsonStr: string): {[any]: any}?
    GG._HttpServiceCache = GG._HttpServiceCache or GG.GetService(game, "HttpService");
    local suc, res = pcal(function()
        return GG._HttpServiceCache:JSONDecode(jsonStr);
    end);
    return suc and res or nil;
end;

-- Serialize table to Lua code string (optimized with table.concat)
GG.tableToLuaCode = function(tbl: {[any]: any}, name: string?): string
    name = name or "tbl";
    local function serialize(t: {[any]: any}, indent: string?): string
        indent = indent or "";
        local parts: {string} = {"{\n"};
        for k, v in pairs(t) do
            local key = (type(k) == "string") and strformat("[%q]", k) or "[" .. tos(k) .. "]";
            local value = (type(v) == "table") and serialize(v, indent .. "    ")
                or (type(v) == "string") and strformat("%q", v)
                or tos(v);
            tablein(parts, indent .. "    " .. key .. " = " .. value .. ",\n");
        end;
        tablein(parts, indent .. "}");
        return tconcat(parts);
    end;

    return name .. " = " .. serialize(tbl) .. ";";
end;

-- Serialize table
-- if instance/object, need attribute/property serialization handling
GG.tableToList = function(tbl: {[any]: any}, transformFunc: (any, any) -> any): {[any]: any}
    local newTbl: {[any]: any} = {};
    for k, v in pairs(tbl) do
        local transformedValue = transformFunc(k, v);
        tablein(newTbl, transformedValue);
    end;
    return newTbl;
end;

-- Serialize list {a,a,a,b,c} to set {a,b,c} (optimized - single pass)
GG.listToSet = function(list: {any}): {[any]: boolean}
    local set: {[any]: boolean} = {};
    for i = 1, #list do
        set[list[i]] = true;
    end;
    return set;
end;

-- ESPT table for ESP module
GG.ESPT = GG.ESPT or {};

------------- Asset Storage Modules -------------

-- AssetStorage for dynamic module loading
GG.AssetStorage = {};

-- Languages module from M.lua
GG.AssetStorage.Languages = function(): nil
    if ScriptCache.Languages then return; end;
    if GG.GameId == 1 then
        ScriptCache.Languages = {
            {
                Key = "Hello",
                Values = {
                    ["en"] = "Hello",
                    ["th"] = "สวัสดี"
                };
            };
        };
    end;
end;

-- Localization module from M.lua
GG.AssetStorage.Localization = function(): nil
    if GG.SetUpLanguage and GG.ApplyLanguage then return; end;
    GG.SetUpLanguage = function(entries: {[nil]: {Key: string, Values: {[string]: string}}}): nil
        ScriptCache.localTable = (ScriptCache.localTable and ScriptCache.localTable.Parent and ScriptCache.localTable) or GG.Instancen("LocalizationTable", GG.W);
        ScriptCache.localTable.DevelopmentLanguage = GG.LocalizationService.SystemLocaleId;
        ScriptCache.localTable:SetEntries(entries);
    end;
    GG.ApplyLanguage = function(lang: string, word: string): string
        return ScriptCache.localTable:GetString(lang, word);
    end;
end;

-- GraphicsPlay module (GCP) from M.lua
GG.AssetStorage.GraphicsPlay = function(): {[string]: (any) -> (...any)}
    if GG.GCP then return GG.GCP; end;
    GG.GCP = {};
    function GG.GCP:ApplyLowest(className: string, at: Instance): nil
        if not at or not at.Parent then return; end;
    end;
    function GG.GCP:ApplyAll(at: Instance, method: string, fors: {string}): nil
        for _, v in pir((method == "Descendants" and GG.GetDescendants(at)) or (method == "Children" and GG.GetChildren(at))) do
            if tablef(fors, v.ClassName) then
                self:ApplyLowest(v.ClassName, v);
            end;
        end;
    end;
    return GG.GCP;
end;

-- ESPModl module from M.lua - ESP (Extra Sensory Perception)
GG.AssetStorage.ESPModl = function(): {[string]: (any) -> (...any)}?
    local ESPF = {};
    function ESPF:Clear()
        for _, v in pir(GG.ESPT) do
            if v and v.Parent then
                GG.Destroy(v, true);
            end;
        end;
    end;
    function ESPF:CreateBox(obj: Instance, dat: {targetObj: Instance, Color: Color3, Size: Vector3, isneed: boolean, BoxOnly: boolean}): BoxHandleAdornment
        local Box: BoxHandleAdornment = GG.Instancen("BoxHandleAdornment", dat.targetObj);
        Box.Color3 = dat.Color;
        Box.AlwaysOnTop = true;
        Box.Size = dat.Size;
        Box.Transparency = 0.5;
        Box.Adornee = dat.targetObj;
        Box.ZIndex = 1;

        if dat.BoxOnly then
            tablein(ESPT, Box);
            return Box;
        end;

        local Billboard: BillboardGui = GG.Instancen("BillboardGui", dat.targetObj);
        Billboard.Adornee = dat.targetObj;
        Billboard.AlwaysOnTop = true;
        Billboard.Size = Dim2(0, 100, 0, 30);
        Billboard.StudsOffset = Vec3(0, dat.Size.Y / 2 + 1, 0);

        local Label: TextLabel = GG.Instancen("TextLabel", Billboard);
        Label.Size = Dim2(1, 0, 1, 0);
        Label.BackgroundTransparency = 1;
        Label.Text = GG.GetAttribute(obj, "Username") or obj.Name;
        Label.TextColor3 = dat.Color;
        Label.TextStrokeTransparency = 0.2;
        Label.Font = Enum.Font.SourceSansBold;
        Label.TextScaled = true;

        tablein(GG.ESPT, Box);
        tablein(GG.ESPT, Billboard);

        return Box;
    end;
    function ESPF:ESP(obj: Instance, Color: Color3, Size: Vector3, isneed: boolean, BoxOnly: boolean): nil
        if not obj or typeof(obj) ~= 'Instance' then return; end;
        local dat = {
            targetObj = nil;
            Color = Color or fromRGB(255, 255, 255);
            Size = Size or Vec3(5, 5, 5);
            isneed = isneed or false;
            BoxOnly = BoxOnly or false;
        };

        if dat.isneed then
            if GG.IsA(obj, "Model") then
                dat.targetObj = GG.FindFirstChild(obj, "HumanoidRootPart") or GG.FindFirstChild(obj, "RootPart");
                if not dat.targetObj then
                    dat.targetObj = GG.FindFirstChildWhichIsA(obj, "BasePart", true);
                end;
            end;
        end;

        dat.targetObj = dat.targetObj or obj;
        if not dat.targetObj then return; end;

        return self:CreateBox(obj, dat);
    end;
    return ESPF;
end;

-- Wind module from M.lua - WindUI helper functions
GG.AssetStorage.Wind = function(): {[string]: (any) -> (...any)}?
    local Windy: {[string]: (any) -> (...any)} = {};
    function Windy:UITracking(key: number): any
        if key == 1 then
            return function()
                if ScriptCache.Window then
                    return ScriptCache.Window.Destroyed;
                end;
            end;
        end;
    end;
    function Windy:AutoSetupToggle(a: tab, b: {any}, c: any): {[string]: any}
        ScriptCache.NewToggle = a:Toggle(b);
        if c then ScriptCache.NewToggle:Set(c); end;
        ScriptCache.PanicConnect = ScriptCache.PanicConnect or {};
        ScriptCache.PanicConnect[#ScriptCache.PanicConnect + 1] = ScriptCache.NewToggle;
        return ScriptCache.NewToggle;
    end;
    function Windy:AutoSetupKeybind(a: tab, b: {any}, c: any): {[string]: any}
        b.Value = c.Name;
        ScriptCache.NewKeybind = a:Keybind(b);
        return ScriptCache.NewKeybind;
    end;
    function Windy:IsGamePause(wind): any
        if not GG.selff.GameplayPaused or ScriptCache.AlreadyNotifyPause then return; end;
        ScriptCache.AlreadyNotifyPause = true;
        return tspawn(function()
            wind:Notify({
                Title = "<font color='rgb(255,0,0)'>ALERT</font>",
                Content = "YOUR GAMEPLAY HAS BEEN PAUSE. Script is waiting until this problem is fully fix or gameplay load.",
                Icon = "circle-alert",
                Duration = 20,
            });
            twait(20);
            ScriptCache.AlreadyNotifyPause = false;
        end);
    end;
    function Windy:GetConfigFromPath(pt: string, rp: string): string
        pt = rp .. "/" .. pt;
        if ScriptCache.AutoConfigPathCache then
            if ScriptCache.AutoConfigPathCache[pt] then
                return ScriptCache.AutoConfigPathCache[pt];
            end;
        end;
        local Splited = strsplit(pt, "/");
        local FullPath = GG.Configs or {};
        for _, v in pir(Splited) do
            FullPath = FullPath[v];
            if FullPath == nil then
                return nil;
            end;
        end;
        ScriptCache.AutoConfigPathCache = ScriptCache.AutoConfigPathCache or {};
        ScriptCache.AutoConfigPathCache[pt] = FullPath;
        return FullPath;
    end;
    function Windy:VisibilityModuleSet(ui: {[string]: any}): nil
        local main: Frame = nil;
        if ui.ToggleFrame then
            main = ui.ToggleFrame.UIElements.Main;
        elseif ui.DropdownFrame then
            main = ui.DropdownFrame.UIElements.Main;
        elseif ui.SliderFrame then
            main = ui.SliderFrame.UIElements.Main;
        elseif ui.ButtonFrame then
            main = ui.ButtonFrame.UIElements.Main;
        end;
        if main then
            main.Visible = true;
        end;
    end;
    return Windy;
end;

-- Files module from M.lua - File system utilities
GG.AssetStorage.Files = function(): nil
    if GG.FileSys then return; end;
    GG.FileSys = {};
    local FileSysOrigin = "FlowXS/";

    function GG.FileSys:Continue(fileName: string, content: string): nil
        if appendfile and isfile then
            return (isfile(fileName) and appendfile(fileName, content));
        end;
        return warn("[ScriptLoader] Files:Continue - appendfile or isfile is not a valid function.");
    end;

    function GG.FileSys:ListFrom(folderName: string, isFullname: boolean?, filesynx: string?): {string}
        if listfiles and isfolder then
            local ok, files = pcal(listfiles, FileSysOrigin .. folderName);
            if not ok then return {}; end;
            local list: {string} = {};
            for _, f in ipir(files) do
                local correctedName = f;
                if isFullname then
                    -- listfiles already returns full paths, use them directly
                    correctedName = f;
                else
                    -- Extract just the filename without path/extension
                    correctedName = f:match("([^/\\]+)$") or f;
                end;
                if filesynx then
                    correctedName = correctedName .. filesynx;
                end;
                tablein(list, correctedName);
            end;
            return list;
        end;
        warn("[ScriptLoader] Files:ListFrom - listfiles or isfolder is not a valid function.");
        return {};
    end;

    function GG.FileSys:WriteFrom(folderName: string, fileName: string, content: string): nil
        if isfolder and writefile then
            local datas = content;
            if type(datas) == 'table' then
                GG._HttpServiceCache = GG._HttpServiceCache or GG.GetService(game, "HttpService");
                datas = GG._HttpServiceCache:JSONEncode(datas);
            end;
            if not isfolder(FileSysOrigin .. folderName) then
                makefolder(FileSysOrigin .. folderName);
            end;
            return writefile(FileSysOrigin .. folderName .. "/" .. fileName, datas);
        end;
        return warn("[ScriptLoader] Files:WriteFrom - isfolder or writefile is not a valid function.");
    end;

    function GG.FileSys:ConvertTo(data: any, format: string): any
        if format == "Lua" then
            if type(data) == 'string' then
                return "return function() " .. data .. "end";
            end;
            return warn("[ScriptLoader] Files:ConvertTo - Error: Argument #1 must be string for 'Lua' format.");
        elseif format == "LuaJA" then
            if type(data) == 'table' then
                local str = "{";
                local first = true;

                for k, v in pairs(data) do
                    if not first then
                        str = str .. ",\n";
                    end;
                    first = false;

                    local keyStr = "[\"" .. tos(k) .. "\"]";
                    local valStr = "\"" .. tos(v) .. "\"";
                    str = str .. keyStr .. " = " .. valStr;
                end;

                str = str .. "}";
                return "return " .. str;
            end;
            return warn("[ScriptLoader] Files:ConvertTo - Error: Argument #1 must be table for 'LuaJA' format.");
        elseif format == "JSON" then
            if type(data) == 'table' then
                return GG.tableToJSON(data);
            end;
            return warn("[ScriptLoader] Files:ConvertTo - Error: Argument #1 must be table for 'JSON' format.");
        elseif format == "Encrypt" then
            return warn("[ScriptLoader] Files:ConvertTo - Log: You are currently using demo filesystem.");
        end;
    end;

    function GG.FileSys:RepairTbl(tbl: {[any]: any}): {[any]: any}
        if type(tbl) ~= "table" then
            return { _error = "nilByTTJY" };
        end;

        local function safeRead(innerTbl: {[any]: any}, visited: {[any]: boolean}): {[any]: any}
            if visited[innerTbl] then
                return { _circular = "[Circular Reference]" };
            end;
            visited[innerTbl] = true;

            local newTbl: {[any]: any} = {};
            for k, v in pairs(innerTbl) do
                local typeofv = typeof(v);
                if typeofv == 'Instance' then
                    local desc = "Object is an Instance";
                    if v.Parent then
                        desc = desc .. " | Path is [ " .. v:GetFullName() .. " ]";
                    else
                        desc = desc .. " | Path is [ nil." .. tostring(v) .. " ]";
                    end;
                    newTbl[k] = desc;
                elseif typeofv == 'table' then
                    newTbl[k] = safeRead(v, visited);
                elseif typeofv == 'CFrame' then
                    local components = {v:GetComponents()};
                    newTbl[k] = "Object was CFrame. [ CF(" .. tconcat(components, ", ") .. ") ]";
                elseif typeofv == 'Vector2' then
                    newTbl[k] = "Object was Vector2. [ Vec2(" .. v.X .. ", " .. v.Y .. ") ]";
                elseif typeofv == 'Vector3' then
                    newTbl[k] = "Object was Vector3. [ Vec3(" .. v.X .. ", " .. v.Y .. ", " .. v.Z .. ") ]";
                else
                    newTbl[k] = v;
                end;
            end;
            return newTbl;
        end;

        return safeRead(tbl, {});
    end;
end;

-- Error405 module from M.lua - Discord webhook error reporting
GG.AssetStorage.Error405 = function(): nil
    if GG.Error405 then return; end;
    local lastSent = 0;
    GG.Error405 = {};
    local Error405 = GG.Error405;

    function Error405:safeToString(v: any): string
        local ok, s = pcal(function() return tos(v); end);
        return ok and s or "";
    end;

    function Error405:truncate(s: string, n: number): string
        return (#s <= n) and s or (strsub(s, 1, n - 3) .. "...");
    end;

    function Error405:flattenTable(tbl: {[any]: any}): {string}
        local out: {string} = {};
        local function recurse(t: {[any]: any}, prefix: string?): nil
            prefix = prefix and (prefix ~= "" and prefix .. "." or "") or "";
            for k, v in pairs(t) do
                local key = Error405:safeToString(k);
                if type(v) == "table" then
                    recurse(v, prefix .. key);
                else
                    tablein(out, prefix .. key .. " : " .. Error405:safeToString(v));
                end;
            end;
        end;
        recurse(tbl or {}, "");
        return out;
    end;

    function Error405:configsToEmbeds(configTbl: {[any]: any}): {{title: string, description: string, color: number}}
        local lines = Error405:flattenTable(configTbl or GG.Configs or {});
        local embeds: {{title: string, description: string, color: number}} = {};
        local currentLines: {string} = {};
        local currentLen = 0;

        for i = 1, #lines do
            local line = lines[i] .. "\n";
            if currentLen + #line > 4000 and #currentLines > 0 then
                tablein(embeds, {
                    title = "Configs",
                    description = Error405:truncate(tconcat(currentLines), 4096),
                    color = 4325120
                });
                currentLines = {};
                currentLen = 0;
            end;
            tablein(currentLines, line);
            currentLen += #line;
        end;

        if #currentLines > 0 then
            tablein(embeds, {
                title = "Configs",
                description = Error405:truncate(tconcat(currentLines), 4096),
                color = 4325120
            });
        end;

        if #embeds > 9 then
            local keep = 8;
            local merged: {string} = {};
            for i = keep + 1, #embeds do
                tablein(merged, embeds[i].description);
            end;
            local newEmbeds: {{title: string, description: string, color: number}} = {};
            for i = 1, keep do
                tablein(newEmbeds, embeds[i]);
            end;
            tablein(newEmbeds, {
                title = "Configs (continued)",
                description = Error405:truncate(tconcat(merged, "\n"), 4096),
                color = 4325120
            });
            embeds = newEmbeds;
        end;

        return embeds;
    end;

    function Error405:sanitizeEmbed(e: {title: any, description: any, color: any}): {title: string, description: string, color: number}
        return {
            title = Error405:truncate(Error405:safeToString(e.title), 256),
            description = Error405:truncate(Error405:safeToString(e.description), 4096),
            color = mfloor(ton(e.color) or 0)
        };
    end;

    function Error405:sendRequest(bodyStr: string): boolean?
        if not GG.ErrorURL then return; end;
        return pcal(function()
            return GG.Request({
                Url = GG.ErrorURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = bodyStr
            });
        end);
    end;

    function Error405:sendWebhook(errorMsg: string, stackTrace: string?, scriptObj: any?): boolean
        local now = otime();
        if now - lastSent < 1 then return false; end;
        lastSent = now;

        local scriptName = "UnknownScript";
        if scriptObj then
            pcal(function()
                scriptName = (scriptObj.GetFullName and GG.GetFullName(scriptObj)) or tos(scriptObj);
            end);
        end;

        local HttpService = GG.GetService(game, "HttpService");
        local content = Error405:truncate(strformat(
            "**Error Detected**\n```time : %s\nuser : %s\n```",
            CommonF and CommonF:ReadDate() or odate("%Y-%m-%d %H:%M:%S", otime()),
            GG.selff and GG.selff.Name or "Anonymous"
        ), 2000);

        local embeds = Error405:configsToEmbeds(GG.Configs);
        tablein(embeds, Error405:sanitizeEmbed({
            title = "Error",
            description = strformat(
                "Script: %s\n\nMessage:\n%s\n\nStacktrace:\n%s",
                Error405:safeToString(scriptName),
                Error405:safeToString(errorMsg),
                Error405:safeToString(stackTrace or "")
            ),
            color = 16711680;
        }));

        while #embeds > 10 do
            table.remove(embeds, 1);
        end;

        local payload = { content = content, embeds = embeds };
        return Error405:sendRequest(HttpService:JSONEncode(payload));
    end;
end;

-- SensitiveService module from M.lua - Function hooking utilities
GG.AssetStorage.SensitiveService = function(): nil
    if GG.SensitiveServiceLoaded then return; end;
    local RawC: {any: any} = {};

    GG.SLow_ForceSelfThisFunction = function(key: string): nil
        if not GG[key] or type(GG[key]) ~= "function" then
            return warn("[ScriptLoader] SensitiveService - Invalid key for SLow_ForceSelfThisFunction:", key);
        end;
        local originalFunc = clonefunction(GG[key]);
        GG[key] = function(...)
            originalFunc(...);
            return originalFunc;
        end;
        tablein(RawC, GG[key]);
    end;

    GG.SLow_SelfThisFunction = function(key: string): nil
        if not GG[key] or type(GG[key]) ~= "function" then
            return warn("[ScriptLoader] SensitiveService - Invalid key for SLow_SelfThisFunction:", key);
        end;
        local originalFunc = clonefunction(GG[key]);
        GG[key] = function(...)
            local Return = originalFunc(...);
            if Return then return Return; end;
            return originalFunc;
        end;
        tablein(RawC, GG[key]);
    end;

    GG.Lower_ForceSelfThisFunction = function(key: string): nil
        if not GG[key] or type(GG[key]) ~= "function" then
            return warn("[ScriptLoader] SensitiveService - Invalid key for Lower_ForceSelfThisFunction:", key);
        end;
        local hooked = nil;
        hooked = GG.LowerC(GG[key], newcclosure(function(...)
            hooked(...);
            return GG[key];
        end));
        tablein(RawC, GG[key]);
    end;

    GG.Lower_SelfThisFunction = function(key: string): nil
        if not GG[key] or type(GG[key]) ~= "function" then
            return warn("[ScriptLoader] SensitiveService - Invalid key for Lower_SelfThisFunction:", key);
        end;
        local hooked = nil;
        hooked = GG.LowerC(GG[key], newcclosure(function(...)
            local Return = hooked(...);
            if Return then return Return; end;
            return GG[key];
        end));
        tablein(RawC, GG[key]);
    end;

    GG.Restore_SensitiveService = function(offset: any): nil
        return tEach(RawC, function(_, v)
            if v == offset then
                pcal(function()
                    GG.ResetC(offset);
                    table.remove(RawC, _);
                end);
            end;
        end);
    end;

    GG.SensitiveServiceLoaded = true;
end;

-- QueueService module from M.lua - Teleport queue management
GG.AssetStorage.QueueService = function(): nil
    if GG.QueueServiceLoaded then return; end;
    ScriptCache.OnTeleportCC = nil;
    ScriptCache.OnTeleportCC2 = nil;
    ScriptCache.f_I_table = {};
    ScriptCache.f_n_table = {};

    GG.Q_UploadFkey = function(key: any, f: any): nil
        ScriptCache.f_I_table[key] = f;
    end;

    GG.Q_UploadFNokey = function(f: any): nil
        tablein(ScriptCache.f_n_table, f);
    end;

    GG.Remove_Q_FKey = function(key: any): nil
        ScriptCache.f_I_table[key] = nil;
    end;

    GG.Remove_Q_FNokey = function(): nil
        ScriptCache.f_n_table = {};
    end;

    GG.Q_Connect = function(States: {any}, isSecure: boolean, queueStr: string?): nil
        if ScriptCache.OnTeleportCC then
            ScriptCache.OnTeleportCC:Disconnect();
            ScriptCache.OnTeleportCC = nil;
        end;

        ScriptCache.OnTeleportCC = GG.selff.OnTeleport:Connect(function(State: any)
            if GG.ONTCC and tablef(States, State) then
                table.foreach(ScriptCache.f_I_table, function(i, v)
                    return isSecure and pcal(v) or v();
                end);
                table.foreach(ScriptCache.f_n_table, function(i, v)
                    return isSecure and pcal(v) or v();
                end);
                if queueStr then
                    return queueOT(queueStr);
                end;
            end;
        end);
    end;

    GG.Q_Disconnect = function(): nil
        if ScriptCache.OnTeleportCC then
            ScriptCache.OnTeleportCC:Disconnect();
            ScriptCache.OnTeleportCC = nil;
        end;
    end;

    GG.Q_Connect_Get = function(States: {any}, isSecure: boolean, func: (() -> string)?): nil
        if ScriptCache.OnTeleportCC2 then
            ScriptCache.OnTeleportCC2:Disconnect();
            ScriptCache.OnTeleportCC2 = nil;
        end;

        ScriptCache.OnTeleportCC2 = GG.selff.OnTeleport:Connect(function(State: any)
            if GG.ONTCC2 and tablef(States, State) then
                tEach(ScriptCache.f_I_table, function(i, v)
                    return isSecure and pcal(v) or v();
                end);
                tEach(ScriptCache.f_n_table, function(i, v)
                    return isSecure and pcal(v) or v();
                end);
                local qStr = func and func();
                if qStr then
                    return queueOT(qStr);
                end;
            end;
        end);
    end;

    GG.Q_Disconnect2 = function(): nil
        if ScriptCache.OnTeleportCC2 then
            ScriptCache.OnTeleportCC2:Disconnect();
            ScriptCache.OnTeleportCC2 = nil;
        end;
    end;

    GG.QueueServiceLoaded = true;
end;

-- Common Functions module
if not CommonF then
    CommonF = {};
end;
GG.CommonF = CommonF;  -- Always assign GG.CommonF, even on reload

if not CommonF.TableToIndex then
    -- Local aliases for commonly used functions (use built-ins directly for safety)
    local tablein = GG.tble.insert;
    local tEach = GG.tble.foreach;

    -- Convert table to index-based array
    function CommonF:TableToIndex(indexTable: {[any]: any}): {[any]: any}
        if not indexTable then return {}; end;
        local newTbl: {[any]: any} = {};
        for i, v in pairs(indexTable) do
            tablein(newTbl, i);
        end;
        return newTbl;
    end

    -- Check if two tables have equal length
    function CommonF:tEqual(a: {[any]: any}, b: {[any]: any}): boolean
        local ca, cb = 0, 0;
        tEach(a, function() ca += 1 end);
        tEach(b, function() cb += 1 end);
        return ca == cb;
    end

    -- Convert color to nearest primary color
    function CommonF:ColortoPrimary(color: Color3): Color3
        local r, g, b = color.R, color.G, color.B;
        if r >= g and r >= b then
            return fromRGB(255, 0, 0);
        elseif g >= r and g >= b then
            return fromRGB(0, 255, 0);
        else
            return fromRGB(0, 0, 255);
        end;
    end

    -- Simulate key press
    function CommonF:SKey(key: Enum.KeyCode): nil
        return GG.VirtualInputManager:SendKeyEvent(true, key, false, game);
    end

    -- Simulate key release
    function CommonF:OffKey(key: Enum.KeyCode): nil
        return GG.VirtualInputManager:SendKeyEvent(false, key, false, game);
    end

    -- Simulate key press with duration
    function CommonF:CallKey(key: Enum.KeyCode, c: number?): nil
        return self:SKey(key), twait(c or 0), self:OffKey(key);
    end

    -- Get list of player names
    function CommonF:RefreshPlayer(): {string}
        local tbl: {string} = {};
        for _, v in pairs(GG.P:GetPlayers()) do
            tablein(tbl, v.Name);
        end;
        return tbl;
    end

    -- Find nearest player
    function CommonF:GetNearestPlayer(maxDist: number?): (Player?, number?)
        local nearest, dista = nil, mhuge;
        local maxDistance = maxDist or 100;
        for _, p in pairs(GG.P:GetPlayers()) do
            if p ~= GG.selff and GG.rootHum(p.Character) then
                local d = GG.dist(GG.rootHum(p.Character));
                if d < dista and d < maxDistance then
                    dista = d;
                    nearest = p;
                end;
            end;
        end;
        return nearest, dista;
    end

    -- Check if two parts are within distance
    function CommonF:isPartNearPart(part1: BasePart, part2: BasePart, distance: number): boolean
        if part1 and GG.IsA(part1, "BasePart") and part2 and GG.IsA(part2, "BasePart") then
            local partDistance = (part1.Position - part2.Position).Magnitude;
            return partDistance <= distance;
        else
            return false;
        end;
    end

    -- Get current time of day (Day/Night)
    function CommonF:GetTime(): string
        local currentTime: number = GG.L.ClockTime;
        if currentTime >= 6 and currentTime < 18 then
            return "Day";
        else
            return "Night";
        end;
    end

    -- Get current date/time string (GMT+7)
    function CommonF:ReadDate(): string
        return odate("%Y-%m-%d %H:%M:%S", otime()) .. " +07:00";
    end

    -- Set lighting technology
    function CommonF:LTech(tech: string): nil
        GG.L.Technology = Enum.Technology[tech];
    end

    -- Equip tool to humanoid
    function CommonF:HumanoidEquip(Tool: Tool): nil
        if not Tool or not GG.selc or not Tool.Parent or not Tool.Parent.Parent then return; end;
        local Humanoid: Humanoid = GG.FindFirstChildOfClass(GG.selc, "Humanoid");
        return Humanoid and Humanoid:EquipTool(Tool);
    end

    -- Alias for EquipTool (common naming)
    function CommonF:EquipTool(Tool: Tool): nil
        return CommonF:HumanoidEquip(Tool);
    end

    -- Teleport player
    function CommonF:Tp(cf: CFrame | Model | BasePart | Part, t: number?): nil
        if not GG.HumRSelf or not cf then return; end;
        
        if GG.IsA(cf, "Model") then
            local root, hum = GG.rootHum(cf);
            if root then
                GG.HumRSelf.CFrame = root.CFrame;
            end;
        elseif GG.IsA(cf, "BasePart") then
            GG.HumRSelf.CFrame = cf.CFrame;
        elseif GG.IsA(cf, "CFrame") then
            GG.HumRSelf.CFrame = cf;
        end;

        if not t then return; end;
        return true, twait(t);
    end

    -- TeleportAndLook - Teleport to target AND look at it
    function CommonF:TpAL(cf: CFrame | Model | BasePart | Part, t: number?): nil
        if not GG.HumRSelf or not cf then return; end;

        local targetCFrame = nil;

        if GG.IsA(cf, "Model") then
            local root = GG.rootHum(cf);
            if root then
                -- Teleport to root position AND look in target's facing direction
                local lookVector = root.CFrame.lookVector;
                targetCFrame = GG.CFLook(root.Position, root.Position + lookVector);
            end;
        elseif GG.IsA(cf, "BasePart") then
            -- Teleport to part position AND look in part's facing direction
            local lookVector = cf.CFrame.lookVector;
            targetCFrame = GG.CFLook(cf.Position, cf.Position + lookVector);
        elseif typeof(cf) == "CFrame" then
            -- For CFrame input, just use it directly (already has position + rotation)
            targetCFrame = cf;
        end;

        if targetCFrame then
            GG.HumRSelf.CFrame = targetCFrame;
            if not t then return; end;
            return true, twait(t);
        end;
    end

    -- Anchor/Unanchor HumanoidRootPart
    function CommonF:Anchored(bool: boolean): nil
        if not GG.HumRSelf then return; end;
        GG.HumRSelf.Anchored = bool;
    end

    -- Create/Get float part for anti-fall
    function CommonF:MakeFloatPart(): BasePart
        local selcRootX = GG.FindFirstChild(GG.W, "selcRootX");
        local UFPart: BasePart;
        if not selcRootX then
            UFPart = GG.Instancen("Part");
            UFPart.Size = Vec3(2, 0.2, 1.5);
            UFPart.Material = Enum.Material.Grass;
            UFPart.Anchored = true;
            UFPart.Transparency = 1;
            UFPart.Parent = GG.W;
            UFPart.Name = "selcRootX";
        else
            UFPart = selcRootX;
        end;
        return UFPart;
    end

    -- Update client state (Float, Noclip, WalkSpeed, JumpPower)
    function CommonF:UpdateClientState(which: string): (...any) -> ...any
        if which == "Float" then
            local FloatYeilding_Var = CF(0, -10000, 0);
            local FloatYeilding_Var_Use = CF(0, -3.1, 0);
            return function(ForceFloat: boolean | string, HumRSelf: BasePart, configValue: boolean?): any
                if not HumRSelf then return; end;
                local UFPart = CommonF:MakeFloatPart();
                if not UFPart then return; end;

                if configValue or ForceFloat then
                    if not ForceFloat then
                        UFPart.CFrame = FloatYeilding_Var;
                    elseif ForceFloat == "None" then
                        if configValue then
                            UFPart.CFrame = HumRSelf.CFrame * FloatYeilding_Var_Use;
                        else
                            UFPart.CFrame = HumRSelf.CFrame * FloatYeilding_Var;
                        end;
                    elseif ForceFloat == true then
                        UFPart.CFrame = HumRSelf.CFrame * FloatYeilding_Var_Use;
                    end;
                else
                    UFPart.CFrame = FloatYeilding_Var;
                end;
                return;
            end;
        elseif which == "Noclip" then
            return function(enable: boolean): nil
                if enable then
                    for _, child in pairs(GG.selc and GG.GetDescendants(GG.selc) or {}) do
                        if GG.IsA(child, "BasePart") and child.Name ~= "bobber" then
                            child.CanCollide = false;
                        end;
                    end;
                end;
                return;
            end;
        end;

        if which == "WalkSpeed" then
            return function(speed: number, enable: boolean): nil
                if not enable or not GG.selc or not GG.FindFirstChildOfClass(GG.selc, "Humanoid") then return; end;
                GG.selc.Humanoid.WalkSpeed = speed;
            end;
        elseif which == "JumpPower" then
            return function(power: number, enable: boolean): nil
                if not enable or not GG.selc or not GG.FindFirstChildOfClass(GG.selc, "Humanoid") then return; end;
                GG.selc.Humanoid.JumpPower = power;
                GG.selc.Humanoid.UseJumpPower = true;
            end;
        end;

        if which == "WalkSpeedC" then
            return function(speed: number, enable: boolean, ConfigWalkSpeed: number?): nil
                if enable then
                    if not GG.WalkSpeedConnector then
                        GG.SecureSelcSaved = GG.FindFirstChild(GG.selc, "Humanoid");

                        if GG.SecureSelcSaved and GG.SecureSelcSaved.Parent then
                            GG.WalkSpeedConnector = GG.SecureSelcSaved:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                                GG.SecureSelcSaved.WalkSpeed = ConfigWalkSpeed or speed;
                            end);
                            GG.SecureSelcSaved.WalkSpeed = speed;
                        end;
                    else
                        if GG.SecureSelcSaved and GG.SecureSelcSaved.Parent then
                            GG.SecureSelcSaved.WalkSpeed = speed;
                        end;
                        if GG.SecureSelcSaved ~= GG.FindFirstChild(GG.selc, "Humanoid") then
                            if GG.WalkSpeedConnector then
                                GG.WalkSpeedConnector:Disconnect();
                                GG.WalkSpeedConnector = nil;
                            end;
                        end;
                    end;
                else
                    if GG.WalkSpeedConnector then
                        GG.WalkSpeedConnector:Disconnect();
                        GG.WalkSpeedConnector = nil;
                        if GG.SecureSelcSaved then
                            GG.SecureSelcSaved.WalkSpeed = 16;
                        end;
                    end;
                end;
            end;
        end;
    end

    -- Find proximity prompt in table matching condition
    function CommonF:findPrompt(tbl: {}, condition: (ProximityPrompt) -> boolean?): ProximityPrompt?
        for _, v in pairs(tbl) do
            if typeof(v) == "Instance" and v:IsA("ProximityPrompt") and (not condition or condition(v)) then
                return v;
            end;
        end;
    end

    -- Rejoin same server
    function CommonF:Rejoin(): nil
        return GG.TeleportService:TeleportToPlaceInstance(GG.PlaceId, game.JobId, GG.selff);
    end

    ------------- Notification System -------------

    -- Notification function (UI-agnostic, can be overridden by UI libraries)
    -- Default: Console output via warn()
    -- Override: Use SetNotify() to replace with UI library notifications
    function CommonF:Notify(title: string, message: string, duration: number?): nil
        duration = duration or 3;
        -- Use warn() for visibility in console
        warn("[" .. tostring(title) .. "] " .. tostring(message));
    end

    -- Allow UI libraries (Fluent, WindUI, etc.) to override the notification system
    -- Example: CommonF:SetNotify(function(title, msg, dur) Fluent:Notify({Title=title, Content=msg, Duration=dur}) end)
    function CommonF:SetNotify(fn: (string, string, number?) -> nil): nil
        if type(fn) == "function" then
            GG.NotifyFunction = fn;
            -- Override the Notify method to use the custom function
            self.Notify = function(_, title: string, message: string, duration: number?)
                duration = duration or 3;
                fn(title, message, duration);
            end;
        else
            warn("[ScriptLoader] SetNotify: Provided argument is not a function");
        end;
    end

    function CommonF:ValidHumanoid(humanoid: Humanoid): boolean
        return humanoid and GG.IsA(humanoid, "Humanoid") and humanoid.Parent and humanoid.Health > 0;
    end

    function CommonF:spawnThread(func: () -> nil): thread
        local co = GG.coru.create(func);
        GG.coru.resume(co);
        return co;
    end

    function CommonF:Threads(name: string, value: boolean, func: () -> nil): thread?
        if not GG.Threads then
            GG.Threads = {};
        end;

        -- Stop existing thread if it exists
        if GG.Threads[name] then
            local status = GG.coru.status(GG.Threads[name]);
            if status == "suspended" or status == "running" then
                GG.coru.close(GG.Threads[name]);
            end;
            GG.Threads[name] = nil;
        end;

        if not value then
            return;
        end;

        -- create new thread
        local co = GG.coru.create(func);
        GG.Threads[name] = co;
        GG.coru.resume(co);
        return co;
    end

    function CommonF:StopThread(name: string): boolean
        if GG.Threads and GG.Threads[name] then
            local co = GG.Threads[name];
            local status = GG.coru.status(co);
            if status == "suspended" or status == "running" then
                GG.coru.close(co);
            end;
            GG.Threads[name] = nil;
            return true;
        end;
        return false;
    end

    function CommonF:StopAllThreads(): number
        local count = 0;
        if GG.Threads then
            for name, co in pairs(GG.Threads) do
                if co then
                    local status = GG.coru.status(co);
                    if status == "suspended" or status == "running" then
                        GG.coru.close(co);
                        count += 1;
                    end;
                    GG.Threads[name] = nil;
                end;
            end;
        end;
        return count;
    end

    function CommonF:IsThreadRunning(name: string): boolean
        if GG.Threads and GG.Threads[name] then
            local status = GG.coru.status(GG.Threads[name]);
            return status == "running" or status == "suspended";
        end;
        return false;
    end

    function CommonF:GetThreadStatus(name: string): string?
        if GG.Threads and GG.Threads[name] then
            return GG.coru.status(GG.Threads[name]);
        end;
        return nil;
    end

    function CommonF:Yield()
        return GG.coru.yield();
    end

    function CommonF:stabilizeCharacter(): nil
        if not GG.selc then return; end;

        local Humanoid: Humanoid = GG.FindFirstChildOfClass(GG.selc, "Humanoid");
        if not Humanoid then return; end;

        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false);
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false);
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false);
    end

    function CommonF:destabilizeCharacter(): nil
        if not GG.selc then return; end;

        local Humanoid: Humanoid = GG.FindFirstChildOfClass(GG.selc, "Humanoid");
        if not Humanoid then return; end;

        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true);
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true);
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true);
    end

    function CommonF:isnetworkowner(part: BasePart): boolean
        if not part or not GG.IsA(part, "BasePart") then return false; end;
        if isnetworkowner then
            return isnetworkowner(part);
        else
            return true;
        end;
        
    end
end;

------------- Return for Module Use -------------

return GG;
