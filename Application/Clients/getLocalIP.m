function ip = getLocalIP()
    import java.net.*
    import java.util.*
    ip = '127.0.0.1'; % fallback
    en = NetworkInterface.getNetworkInterfaces;
    while en.hasMoreElements
        ni = en.nextElement;
        if ~ni.isUp || ni.isLoopback || ni.isVirtual
            continue
        end
        addrs = ni.getInetAddresses;
        while addrs.hasMoreElements
            addr = addrs.nextElement;
            if isa(addr,'java.net.Inet4Address') && ~addr.isLoopbackAddress
                ip = char(addr.getHostAddress);
                return
            end
        end
    end
end
