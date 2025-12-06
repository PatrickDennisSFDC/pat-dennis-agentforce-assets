public class VisitAccess {
    
    static Set<String> accessLevels = new Set<String>{'read', 'edit'};
    
    public static void insertVisitAccess(Visit visit, User user, String accessType) {
        insertVisitAccess(visit, new List<User>{user}, accessType);
    }
    
    public static void insertVisitAccess(Visit visit, Id objectId, String accessType) {
        if(isUser(objectId)) {
            insertVisitAccess(visit, new User(id=objectId), accessType);
        }
    }
    
    public static void insertVisitAccess(Visit visit, List<User> users, String accessType) {
        if(visit==null || visit.Id==null || users==null || users.isEmpty()) {
            return;
        }
        List<VisitShare> shareVisitList = new List<VisitShare>();
        for(User user: users) {
            if(user==null)
                continue;
            VisitShare shareVisit = New VisitShare();
            shareVisit.ParentId=visit.Id;
            shareVisit.UserOrGroupID = user.Id;
            shareVisit.AccessLevel = accessType;
            shareVisitList.add(shareVisit);
        }
        try{
            Database.insert(shareVisitList);
        } catch(Exception e) {
            System.debug('Unexpected exception : ' + e);
        }
    }
    
    public static void updateVisitAccess(Visit visit, List<Id> oldUsers, List<Id> newUsers, String access) {
        if(visit==null) {
            return;
        }
        if(oldUsers!=null) {
            for(Id userId : oldUsers) {
                if(isUser(userId)) {
                    deleteVisitAccess(visit, new User(id=userId));
                }
            }
        }
        if(newUsers!=null) {
            for(Id userId : newUsers) {
                if(isUser(userId)) {
                    insertVisitAccess(visit, userId, access);
                }
            }
        }
    }
    
    public static void updateVisitAccess(Visit oldVisit, Visit updatedVisit, String access) {
        //Comment this condition if for any update visit need to be shared
        if(oldVisit.VisitorId==updatedVisit.VisitorId) {
            return;
        }
        updateVisitAccess(oldVisit, oldVisit!=null?new List<Id>{oldVisit.VisitorId}:new List<Id>(), updatedVisit!=null?new List<Id>{updatedVisit.VisitorId}:new List<Id>(), access);
    }
    
    //remove user from oldVisit if user does not have any more access to oldVisit, and link user to newVisit
    public static void updateVisitAccess(Visit oldVisit, Visit newVisit, List<User> users, String access) {
        if(users==null || users.isEmpty()) {
            return;
        }
        if(access==null||!accessLevels.contains(access)) {
            access='edit';
        }
        for(User user : users) {
            if(oldVisit!=null)
                deleteVisitAccess(oldVisit, user);
             if(newVisit!=null)
                 insertVisitAccess(newVisit, user, access);
        }
    }
    
        
    //remove user from oldVisit if user does not have any more access to oldVisit, and link user to newVisit
    public static void updateVisitAccess(Visit oldVisit, Visit newVisit, Id objectId, String access) {
          if(isUser(objectId)) {
              updateVisitAccess(oldVisit, newVisit, new List<User>{new User(id=objectId)}, access);
          }
    }
    
    public static void deleteVisitAccess(Visit visit, List<User> users) {
        List<VisitShare> visitShareList = new List<VisitShare>();
        for(User user : users) {
            if(isUserLinkedToVisit(user, visit))
                continue;
            List<VisitShare> visitShare = [select Id from VisitShare where ParentId = :visit.Id and UserOrGroupID = :user.Id and RowCause='Manual'];
            if(!visitShare.isEmpty()) {
                visitShareList.add(visitShare.get(0));
            }
        }
        delete visitShareList;
    }
    
    public static void deleteVisitAccess(Visit visit, User user) {
        deleteVisitAccess(visit, new List<User>{user});
    }
    
    public static void deleteVisitAccess(Visit visit, Id objectId) {
        if(isUser(objectId)) {
            deleteVisitAccess(visit, new User(id=objectId));
        }
    }
    
    public static Boolean isUser(Id objId) {
        if(objId==null)
            return false;
        List<User> users = [select Id from User where Id = :objId];
        return !users.isEmpty();
    }
    
    public static Boolean isUser(Object obj) {
        if(obj==null)
            return false;
        try {
            User user = (User)obj;
        } catch(TypeException e) {
            return false;
        }
        return true;
    }

    public static Boolean isUserLinkedToVisit(User user, Visit visit) {
        List<Visit> visits = [select Id from Visit where VisitorId = :user.Id and Id=:visit.Id];
        List<Visitor> visitors = [select Id from Visitor where AssigneeId = :user.Id and VisitId=:visit.Id];
        return !visits.isEmpty() || !visitors.isEmpty();
    }
}