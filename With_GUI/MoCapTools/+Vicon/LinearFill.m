function markerData = LinearFill(markerData, markerToFill, t0, t1)

    x=markerData.(markerToFill);
    header=x.Header;
    t0_idx=find(header==t0,1);
    t1_idx=find(header==t1,1);
    
    t = header;
    y = x{:,2:end};
    
    interRefRange = ([t0_idx,t1_idx])';
    a=interp1(t(interRefRange),y(interRefRange,:),header(t0_idx+1:t1_idx-1),'linear');
        
    x{t0_idx+1:t1_idx-1,2:end}=a;
    markerData.(markerToFill)=x;
end
