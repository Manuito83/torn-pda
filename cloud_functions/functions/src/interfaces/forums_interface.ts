export interface ForumsApiResponse {
    forumSubscribedThreads?: ForumThread[];
    error?: ApiError;
}

export interface ApiError {
    code: number;
    error: string;
}

export interface ForumThread {
    id: number;
    forum_id: number;
    title: string;
    posts: {
        new: number;
        total: number;
    };
    author: {
        id: number;
        username: string;
        karma: number;
    };
}
